#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/X.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <string.h>
#include <tk.h>
#include <tcl.h>
#include <time.h>

#define XEMBED_MAPPED                   (1 << 0)
#define SYSTEM_TRAY_REQUEST_DOCK    0
#define SYSTEM_TRAY_BEGIN_MESSAGE   1
#define SYSTEM_TRAY_CANCEL_MESSAGE  2

#define IL_LAST(il)				\
{						\
	if (il != NULL){			\
		while (il->next != NULL) 	\
			il=(TrayIcon *)il->next; 	\
	}					\
}

#define IL_FIRST(il) 				\
{						\
	if (il != NULL){			\
		while (il->prev != NULL)	\
			il=(TrayIcon *)il->prev; 	\
	}					\
}

#define IL_APPEND(il,item)  			\
{						\
	if (il != NULL)			\
	{					\
		IL_LAST(il)			\
		il->next=(TrayIcon_ *)item; 	\
		item->prev=(TrayIcon_ *)il; 	\
		il=(TrayIcon *)il->next;   	\
	}else{					\
		il=item;			\
	}					\
}
	
#define IL_PREPEND(il,item)  			\
{						\
	if (il != NULL)				\
	{					\
		IL_FIRST(il)			\
		il->prev=(TrayIcon_ *)item; 	\
		item->next=(TrayIcon_ *)il; 	\
		il=(TrayIcon *)il->prev;   	\
	}else{					\
		il=item;			\
	}					\
}


typedef struct TrayIcon *TrayIcon_;
typedef struct {
	Tk_Window win;
	Tk_PhotoHandle pixmap;
	char *pixmapName;
	const char *pathName;
	int w,h;
	char tooltip[256];
	char cmdCallback[768];
	char cmdCreate[768];
	int mustUpdate;
	int width;
	int height;
	TrayIcon_ *prev;
	TrayIcon_ *next;
} TrayIcon;

static TrayIcon *iconlist=NULL;

/* System tray window ID */
static Window systemtray;
static Display *display;
//static int msgid=0;
Tcl_TimerToken timer=NULL;
//static int tooltip=0;
Tcl_Interp * globalinterp;

/* Set embed information */
static void
xembed_set_info (Tk_Window window, unsigned long  flags)
{
   	unsigned long buffer[2];
 
	/* Get flags */
   	Atom xembed_info_atom = XInternAtom (display,"_XEMBED_INFO",0);
 
   	buffer[0] = 0;                /* Protocol version */
   	buffer[1] = flags;
 
	/* Change the property */
   	XChangeProperty (display,
                    Tk_WindowId(window),
                    xembed_info_atom, xembed_info_atom, 32,
                    PropModeReplace,
                    (unsigned char *)buffer, 2);
}

static void
send_message (Display* dpy,Window w,
		Atom type,long message, 
		long data1, long data2, long data3)
{
    	XEvent ev;
  
    	memset(&ev, 0, sizeof(ev));
    	ev.xclient.type = ClientMessage;
    	ev.xclient.window = w;
    	ev.xclient.message_type = type;
    	ev.xclient.format = 32;
    	ev.xclient.data.l[0] = time(NULL);
    	ev.xclient.data.l[1] = message;
    	ev.xclient.data.l[2] = data1;
    	ev.xclient.data.l[3] = data2;
    	ev.xclient.data.l[4] = data3;

		//trap_errors();
    	XSendEvent(dpy, w, False, NoEventMask, &ev);
    	XSync(dpy, False);
    //if (untrap_errors()) {
	/* Handle failure */
		//printf("Handle failure\n");
    //}
}

/* Procedure that Docks the icon */
static void
DockIcon(ClientData clientData)
{

	Window parent;
	unsigned int ret, atom;
	TrayIcon *icon= clientData;
	char* wm_name;

    Tk_MakeWindowExist(icon->win);

	Tk_SetWindowBackgroundPixmap(icon->win, ParentRelative);

	xembed_set_info(icon->win,XEMBED_MAPPED);

	atom = XInternAtom(display, "_NET_SYSTEM_TRAY_OPCODE", False );
	send_message(display,systemtray, atom,
			SYSTEM_TRAY_REQUEST_DOCK,Tk_WindowId(icon->win),0,0);
}

/* Draw the icon */
static void
DrawIcon (ClientData clientData)
{
	TrayIcon *icon=clientData;
	int x,y;
	unsigned int w,h,b,d;
	int widthImg, heightImg;
	Window r;
	char cmdBuffer[1024];
	XSizeHints *hints = NULL;
	long supplied = 0;

	XGetGeometry(display, Tk_WindowId(icon->win), &r, &x, &y, &w, &h, &b, &d);
	XClearWindow(display, Tk_WindowId(icon->win));

	/*
	 * Here we get the window hints because in some cases the XGetGeometry
	 * function returns the wrong width/height. We only check that 
	 * min_width <= width <= max_width and min_height <= height <= max_height
	 */
	hints = XAllocSizeHints();
	XGetWMNormalHints(display, Tk_WindowId(icon->win), hints, &supplied);
	if( supplied & PMaxSize ) {
		w = (hints->max_width < w) ? hints->max_width : w;
		h = (hints->max_height < h) ? hints->max_height : h;
	}
	if( supplied & PMinSize ) {
		w = (hints->min_width > w) ? hints->min_width : w;
		h = (hints->min_height > h) ? hints->min_height : h;
	}
	if(hints) {
		XFree(hints);
		hints = NULL;
	}

	if (((icon->width != w) || (icon->height != h) || (icon->mustUpdate)) && (icon->cmdCallback[0] != '\0')) {
		snprintf(cmdBuffer,sizeof(cmdBuffer),"%s %u %u",icon->cmdCallback,w,h);
		Tcl_EvalEx(globalinterp,cmdBuffer,-1,TCL_EVAL_GLOBAL);
		icon->mustUpdate = False;
		icon->width = w;
		icon->height = h;
	}
	
	Tk_SizeOfImage(icon->pixmap, &widthImg, &heightImg);
	if (widthImg > w)
		widthImg = w;
	if (heightImg > h)
		heightImg = h;

	if( !Tk_IsMapped(icon->win) )
		Tk_MapWindow(icon->win);
	Tk_RedrawImage(icon->pixmap, 0, 0, widthImg, heightImg, Tk_WindowId(icon->win), (w-widthImg)/2 , (h-heightImg)/2 );

}


/*static void
show_tooltip (ClientData clientdata)
{
	TrayIcon *icon = (TrayIcon *)clientdata;
	if (icon->tooltip != NULL)
	{	
		tooltip=1;
//		printf ("%s\n",icon->tooltip);
	}
	timer=NULL;
}

static void
remove_tooltip (void)
{
	if (tooltip == 1)
	{
		tooltip=0;
	}
}*/


/* Callback function when a message arrives */
static int
MessageEvent (Tk_Window tkwin, XEvent *eventPtr)
{
	printf("Got ClientMessage event\n");
    if( eventPtr->type == ClientMessage ) {
        printf( "Window: %d\n", eventPtr->xclient.window );
        printf( "Atom: %s\n", XGetAtomName(display, eventPtr->xclient.message_type) );
    }
	return 0;
}


/* Callback function when an event happens */
static void
IconEvent (ClientData clientData, register XEvent *eventPtr)
{
	TrayIcon *icon = (TrayIcon *)clientData;

    printf( "Got another Event\n" );
	if ((eventPtr->type == Expose) && (eventPtr->xexpose.count == 0)) {
		if (icon->win != NULL)
			/*horrible hack to redraw the icon when dragging the dock aroun the panels*/
			Tcl_CreateTimerHandler(500, DrawIcon, icon);
		goto redraw;

	} else if (eventPtr->type == ConfigureNotify || eventPtr->type == ResizeRequest) {
		icon->mustUpdate=True;
		goto redraw;
	} /*else if (eventPtr->type == EnterNotify) {
		if (timer == NULL) {
			timer = Tcl_CreateTimerHandler(500, show_tooltip, icon);
		}
	} else if (eventPtr->type == LeaveNotify) {
		if (tooltip==1)
			remove_tooltip();
		if (timer != NULL) {
			Tcl_DeleteTimerHandler(timer);
			timer=NULL;
		}

	}*/

	return;

redraw:
    	if ((icon->win != NULL)) {
		Tcl_DoWhenIdle(DrawIcon, (ClientData) icon);
    	}
}

static void
ImageChangedProc (ClientData clientData,
	int x,
	int y,
	int width,
	int height,
	int imageWidth,
	int imageHeight)
{

	TrayIcon *icon = (TrayIcon *)clientData;

	icon->mustUpdate=True;
	Tcl_DoWhenIdle(DrawIcon, clientData);
}

/* Create the Window that will hold the tray icon */
static int 
CreateIconWin(Tcl_Interp *interp, TrayIcon *icon)
{
	Tk_Window mainw = Tk_MainWindow(interp);
	size_t length;
	char cmdBuffer[1024];

	/* Create the window */
	icon->win=Tk_CreateWindowFromPath(interp, mainw, icon->pathName, NULL);

	DockIcon((ClientData)icon);

	Tk_GeometryRequest( icon->win, 24, 24);

	icon->pixmap=Tk_GetImage(interp,icon->win,icon->pixmapName,ImageChangedProc, (ClientData)icon);

	/* Create callback function for event handling */
	//FIXME: This is setup in the wrong way, we should not refer to mainw, but to the tray window
	unsigned int mask = StructureNotifyMask | ExposureMask | EnterWindowMask | LeaveWindowMask  | PropertyChangeMask;
	Tk_CreateEventHandler(mainw, mask, IconEvent, (ClientData) icon);
	Tk_CreateClientMessageHandler(MessageEvent);

	/* Set default icon size hint */
	XSizeHints *hint = XAllocSizeHints();
	hint->flags |=PMinSize|PMaxSize;
	hint->min_width=24;
	hint->max_width=64;
	hint->min_height=24;
	hint->max_height=64;

	XSetWMNormalHints(display,Tk_WindowId(icon->win),hint);
	XFree(hint);

	snprintf(cmdBuffer,sizeof(cmdBuffer),"%s %u %u",icon->cmdCallback,24,24);
	if (Tcl_EvalEx(globalinterp,cmdBuffer,-1,TCL_EVAL_GLOBAL) == TCL_ERROR) {
		return 0;
	}
	if (Tcl_EvalEx(globalinterp,icon->cmdCreate,-1,TCL_EVAL_GLOBAL) == TCL_ERROR) {
		return 0;
	}
	return 1;
}

/* New tray icon procedure (newti command) */
static int
Tk_TrayIconNew (ClientData clientData,
		Tcl_Interp *interp,
		int objc,
		Tcl_Obj *CONST objv[])
{

	int n;
	char *arg;
	size_t length;
	Tk_Window mainw;
	TrayIcon *icon;

	/* Get memory for trayicon data and zero it*/
	icon = (TrayIcon *) malloc(sizeof(TrayIcon));
	memset((void *) icon, 0, (sizeof(TrayIcon)));
	icon->next = icon->prev=NULL;
	
	mainw=Tk_MainWindow(interp);

	/* Get the first argument string (object name) and check it */
	icon->pathName=Tcl_GetStringFromObj(objv[1],(int *) &length);
	//printf("Arg: %s\n",arg);
	if (icon->pathName == NULL || length < 1 || strncmp(icon->pathName, ".", 1)) {
		Tcl_AppendResult (interp, "bad path name: ", icon->pathName , (char *) NULL);
		return TCL_ERROR;
	}
	
	/* Search in the list if that trayicon window name already exists */
	//printf ("Searching for %s!!\n",arg);
	if (iconlist != NULL)
	{
		IL_FIRST(iconlist)
		
		while (1)
		{
			//printf ("Comparing with %s!!\n",Tk_PathName(iconlist->win));
			if (!strcmp(iconlist->pathName,icon->pathName))
			{
				Tcl_AppendResult (interp, "tray icon ",icon->pathName , " already exist", (char *) NULL);
				return TCL_ERROR;
			}
			if (iconlist->next==NULL)
				break;
			iconlist=(TrayIcon *)iconlist->next;
		}
	}

	/* Parse options */
	for (n=2;n<objc;n++) {
		arg=Tcl_GetStringFromObj(objv[n],(int *) &length);
		if (arg[0] == '-') {
			if (!strncmp(arg,"-pixmap",length)) {
				n++;
				/*Get pixmap name*/
				icon->pixmapName=Tcl_GetStringFromObj(objv[n],(int *) &length);
			} else if (!strncmp(arg,"-tooltip",length)) {
				/* Copy tooltip string */
				n++;
				strcpy (icon->tooltip,Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else if (!strncmp(arg,"-command",length)) {
				/* Copy command string */
				n++;
				strcpy (icon->cmdCallback,Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else if (!strncmp(arg,"-createcb",length)) {
				/* Copy createcb string */
				n++;
				strcpy (icon->cmdCreate,Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else {
				Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
				return TCL_ERROR;
			}
		} else {
			Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
			return TCL_ERROR;
		}
	}

	/* If there's a pixmap file, try to load it */
	if (icon->pixmapName != NULL) {
		if (systemtray != NULL) { /* If the system tray is currently available, create the window */
			if(!CreateIconWin(interp, icon)) {
				return TCL_ERROR;
			}
		}
	}else{
		Tcl_AppendResult (interp, "you must provide a pixmap file", (char *) NULL);
		return TCL_ERROR;
	}
	
	/* Append icon to the icon list */
	IL_APPEND(iconlist,icon)
	
	/* Set result string and return OK */
	Tcl_SetResult(interp, icon->pathName, TCL_STATIC);
	return TCL_OK;
}

/* configureti command */
static int 
Tk_ConfigureIcon (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	int n;
	char *arg;
	size_t length;

	/* Check path name */
	arg=Tcl_GetStringFromObj(objv[1],(int *) &length);
	if (strncmp(arg,".",1))
	{
		Tcl_AppendResult (interp, "bad path name: ",Tcl_GetStringFromObj(objv[1],(int *) &length) , (char *) NULL);
		return TCL_ERROR;
	}
	if (objc < 2)
	{
		Tcl_AppendResult (interp, "what do you want to configure?" , (char *) NULL);
		return TCL_ERROR;
	}
	
	/* Find icon in the list */
	if (iconlist == NULL)
	{
		Tcl_AppendResult (interp, "create a tray icon first" , (char *) NULL);
		return TCL_ERROR;
	}

		
	IL_FIRST(iconlist)
		
	while (1)
	{
		if (!strcmp(iconlist->pathName,arg))
		{
			break;
		}
		if (iconlist->next==NULL)
			Tcl_AppendResult (interp, "tray icon not found: ",arg , (char *) NULL);
			return TCL_ERROR;
		iconlist=(TrayIcon *)iconlist->next;
	}
		
	/* Parse arguments */
	for (n=2;n<objc;n++)
	{
		arg=Tcl_GetStringFromObj(objv[n],(int *) &length);
		if (arg[0] == '-')
		{
			if (!strncmp(arg,"-pixmap",length))
			{
				n++;
				iconlist->pixmapName = Tcl_GetStringFromObj(objv[n],(int *) &length);
			} else if (!strncmp(arg,"-tooltip",length))
			{
				n++;
				strcpy(iconlist->tooltip,Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else if (!strncmp(arg,"-command",length))
			{
				n++;
				strcpy(iconlist->cmdCallback,Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else if (!strncmp(arg,"-createcb",length))
			{
				n++;
				strcpy(iconlist->cmdCreate, Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else {
				Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
				return TCL_ERROR;
			}
		}else{
			Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
			return TCL_ERROR;
		}
	}

	if (iconlist->pixmapName != NULL && iconlist->pixmap != NULL)
	{
		Tk_FreeImage(iconlist->pixmap);
		iconlist->pixmap=Tk_GetImage(interp,iconlist->win,iconlist->pixmapName,ImageChangedProc, (ClientData)iconlist);
		Tcl_DoWhenIdle(DrawIcon, (ClientData) iconlist);
		
	}
	return TCL_OK;
}
/*static int 
Tk_TrayIconBalloon  (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	int found;
	char *arg=NULL;
	size_t length;
  

	arg=Tcl_GetStringFromObj(objv[1],(int *) &length);
	if (strncmp(arg,".",1))
	{
		Tcl_AppendResult (interp, "bad path name: ",Tcl_GetStringFromObj(objv[1],(int *) &length) , (char *) NULL);
		return TCL_ERROR;
	}
	if (objc < 2)
	{
		Tcl_AppendResult (interp, "please give me a balloon message" , (char *) NULL);
		return TCL_ERROR;
	}
	
	found=0;
	if (iconlist == NULL)
	{
		Tcl_AppendResult (interp, "create a tray icon first" , (char *) NULL);
		return TCL_ERROR;
	}

		
	IL_FIRST(iconlist)
		
	while (1)
	{
		if (!strcmp(Tk_PathName(iconlist->win),arg))
		{
			found=1;
			break;
		}
		if (iconlist->next==NULL)
			break;
		iconlist=(TrayIcon *)iconlist->next;
	}

	if (found == 0)
	{
		Tcl_AppendResult (interp, "tray icon not found: ",arg , (char *) NULL);
		return TCL_ERROR;
	}

	msgid++;
	
	arg = Tcl_GetStringFromObj(objv[2],(int *) &length);
	length--;

	send_message(display,systemtray,XInternAtom (display, "_NET_SYSTEM_TRAY_OPCODE", False ),
			SYSTEM_TRAY_BEGIN_MESSAGE,0,length,msgid);
	while (length > 0)
    	{
      		XClientMessageEvent ev;

      		ev.type = ClientMessage;
      		ev.window = Tk_WindowId(iconlist->win);
      		ev.format = 8;
      		ev.message_type = XInternAtom (display,
				     "_NET_SYSTEM_TRAY_MESSAGE_DATA", False);
      		if (length > 20)
		{
	  		memcpy (&ev.data, arg, 20);
	  		length -= 20;
	  		arg += 20;
		}
      		else
		{
	  		memcpy (&ev.data, arg, length);
	  		length = 0;
		}

      		XSendEvent (display,
		  	systemtray, False, NoEventMask, (XEvent *)&ev);
      		XSync (display, False);
    	}	
	return TCL_OK;
}*/

/* Removes the icon from the dock area */
static int 
Tk_RemoveIcon (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	char *arg=NULL;
	size_t length;
	TrayIcon *tmp=NULL;
	
	/* Check path */
	arg=Tcl_GetStringFromObj(objv[1],(int *) &length);
	if (strncmp(arg,".",1))
	{
		Tcl_AppendResult (interp, "bad path name: ",arg , (char *) NULL);
		return TCL_ERROR;
	}
		
	/* Find icon in the list */
	if (iconlist == NULL)
	{
		Tcl_AppendResult (interp, "create a tray icon first" , (char *) NULL);
		return TCL_ERROR;
	}

		
	IL_FIRST(iconlist)
		
	while (1)
	{
		if (!strcmp(iconlist->pathName,arg))
		{
			break;
		}
		if (iconlist->next==NULL)
			Tcl_AppendResult (interp, "tray icon not found: ",arg , (char *) NULL);
			return TCL_OK;
		iconlist=(TrayIcon *)iconlist->next;
	}

	if( iconlist->pixmap != NULL ) {
		Tk_FreeImage(iconlist->pixmap);
	}
	if( iconlist->win != NULL ) {
		Tk_DestroyWindow(iconlist->win);
	}
	
	/* Remove it from the list */
	if (iconlist->next == NULL && iconlist->prev == NULL)
	{
		free(iconlist);
		iconlist=NULL;
	} else if (iconlist->next==NULL)
	{
		tmp = (TrayIcon *)iconlist->prev;
		tmp->next=NULL;
		iconlist->prev=iconlist->next=NULL;
		free(iconlist);
		iconlist=tmp;
	} else if (iconlist->prev==NULL)
	{
		tmp = (TrayIcon *)iconlist->next;
		tmp->prev=NULL;
		iconlist->prev=iconlist->next=NULL;
		free(iconlist);
		iconlist=tmp;
	} else	{
		tmp = (TrayIcon *) iconlist->prev;
		tmp->next = iconlist->next;
		((TrayIcon *)tmp->next)->prev=(TrayIcon_ *)tmp;
		iconlist->prev=iconlist->next=NULL;
		free(iconlist);
		iconlist=tmp;
	}
		
	return TCL_OK;
}


//FIXME: This function should be removed altogether
static int 
Tk_SystemTrayAvailable (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	Tcl_Obj *result;
	result=Tcl_NewIntObj(1);
	
	Tcl_SetObjResult(interp, result);
	return TCL_OK;
}

/* Initialization procedure, called when loading the shared library */
int
Tray_Init (Tcl_Interp *interp)
{
	char buffer[256];
	Atom a;
	Tk_Window mainwin;
	systemtray=0;

	globalinterp = interp;

	//Check TK version is 8.0 or higher
	if (Tk_InitStubs(interp, "8.0", 0) == NULL) {
		return TCL_ERROR;
	}

	//Get main window, and display
	mainwin=Tk_MainWindow(interp);
	display = Tk_Display(mainwin);

	snprintf (buffer, sizeof (buffer), "_NET_SYSTEM_TRAY_S%d",
					XScreenNumberOfScreen(Tk_Screen(mainwin)));
     	/* Get the X11 Atom */
	a=XInternAtom (display,buffer, False);
	/* And get the window ID associated to that atom */
	systemtray=XGetSelectionOwner(display,a);

	/* Create the new trayicon commands */
	Tcl_CreateObjCommand(interp, "newti", Tk_TrayIconNew,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "configureti", Tk_ConfigureIcon,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "removeti", Tk_RemoveIcon,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "systemtray_exist", Tk_SystemTrayAvailable,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
/*	Tcl_CreateObjCommand(interp, "tiballoon", Tk_TrayIconBalloon,
	    	(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);*/

    return TCL_OK;
}

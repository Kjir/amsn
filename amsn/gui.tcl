
namespace eval ::amsn {
   namespace export fileTransferSend fileTransferRecv fileTransferProgress errorMsg 
   
   proc errorMsg { msg } {
      tk_messageBox -type ok -icon error -message $msg -title "[trans title] Error" 
   }
   
   proc fileTransferSend { twn title } {
      global config

      set ipaddr "[::MSN::getMyIP]"

      set w .sendfile$title
      toplevel $w
      wm title $w "[trans sendfile]"
      label $w.msg -justify center -text "[trans enterfilename]"
      pack $w.msg -side top -pady 5

      frame $w.buttons
      pack $w.buttons -side bottom -fill x -pady 2m
      button $w.buttons.dismiss -text [trans cancel] -command "destroy $w"
      button $w.buttons.save -text "[trans ok]" \
        -command "::amsn::FileTransferSendOk $w $twn"
      pack $w.buttons.save $w.buttons.dismiss -side left -expand 1     

      frame $w.top

      frame $w.top.labels
      label $w.top.labels.file -text "[trans filename]:"
      label $w.top.labels.ip -text "[trans ipaddress]:"

      frame $w.top.fields
      entry $w.top.fields.file -width 40
      entry $w.top.fields.ip -width 15 
      checkbutton $w.top.fields.autoip -text "[trans autoip]" -variable config(autoftip)
      
      pack $w.top.fields.file -side top -anchor w
      pack $w.top.fields.ip $w.top.fields.autoip -side left -anchor w -pady 5      
      pack $w.top.labels.file $w.top.labels.ip -side top -anchor e     
      pack $w.top.fields -side right -padx 5
      pack $w.top.labels -side left -padx 5      
      pack $w.top -side top

      if {$config(autoftip)} {
        $w.top.fields.ip insert 0 "$ipaddr"
      } else {
        $w.top.fields.ip insert 0 "$config(myip)"
      }

      focus $w.top.fields.file

      fileDialog2 $w $w.top.fields.file open ""
   }
  
   proc FileTransferSendOk { w sbn } {
      global config
      set filename [ $w.top.fields.file get ]  

      if {$config(autoftip) == 0 } {
        set config(myip) [ $w.top.fields.ip get ]  
        set ipaddr [ $w.top.fields.ip get ]  
      } else {
        set ipaddr [ ::MSN::getMyIP ]  
      }
      

      destroy $w 

      #Calculate a random cookie
      set cookie [expr {[clock clicks]  % (65536 * 8)}]     
      
      status_log "Random generated cookie: $cookie\n"
      
      ::amsn::SendWin [file tail $filename] $cookie
      ::MSN::inviteFT $sbn $filename $cookie $ipaddr
      
      
      return 0
   }
     
   proc fileTransferRecv {filename filesize cookie sb_name} {
      global files_dir
      set answer [tk_messageBox -message "[trans acceptfile $filename $filesize $files_dir]" -type yesno -icon question -title [trans receivefile]]
      if {$answer == "yes"} {
         ::amsn::RecvWin $filename $cookie 
         ::MSN::acceptFT $sb_name $filename $filesize $cookie
      } else {
         ::MSN::rejectFT $sb_name $cookie
      }
   }

   proc SendWin {filename cookie} {
      status_log "Creating send progress window\n"
      set w .ft$cookie
      toplevel $w
      wm title $w "[trans sendfile] $filename"
      wm geometry $w 300x100
      
      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelSending $cookie"
      pack $w.close -side bottom
      
      pack [::dkfprogress::Progress $w.prbar] -fill x -expand 1 -padx 5 -pady 5
      
      
      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelSending $cookie"
   }
   
   proc RecvWin {filename cookie} {
     status_log "Creating receive progress window\n"
      set w .ft$cookie
      toplevel $w
      wm title $w "[trans receivefile] $filename"
      wm geometry $w 300x100

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelReceiving $cookie"
      pack $w.close -side bottom

      pack [::dkfprogress::Progress $w.prbar] -fill x -expand 1 -padx 5 -pady 5
      
      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelReceiving $cookie"     
   }

   
   proc fileTransferProgress {mode cookie bytes filesize} {
      # -1 in bytes to transfer cancelled
      # bytes >= filesize for connection finished
      set w .ft$cookie
      
      if { [winfo exists $w] == 0} {
        return
      }

      if { $mode == "p" } {
	 $w.progress configure -text "[trans listeningon $bytes]"
	 return
      } 

      
      if { $bytes <0 } {
	 $w.progress configure -text "[trans filetransfercancelled]"
      } elseif { $bytes >= $filesize } {
	 ::dkfprogress::SetProgress $w.prbar 100
	 $w.progress configure -text "[trans filetransfercomplete]"
      }
      
      set bytes2 [expr {$bytes/1024}] 
      set filesize2 "[expr {$filesize/1024}] Kb"      
      set cien 100
      set percent [expr {$bytes*100/$filesize}]
      
      if { ($bytes >= $filesize) || ($bytes<0)} {
	 $w.close configure -text "[trans close]" -command "destroy $w"
         wm protocol $w WM_DELETE_WINDOW "destroy $w"
      } elseif { $mode == "r" } {
	 $w.progress configure -text "[trans receivedbytes $bytes2 $filesize2]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      } else {
	 $w.progress configure -text "[trans sentbytes $bytes2 $filesize2]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      }
   }
   
}

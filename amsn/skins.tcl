#!/usr/bin/wish
#########################################################
# skins.tcl v 1.0	2003/07/01   KaKaRoTo
# New skin selector by Alberto (yozko) on 01/19/2004
#########################################################

namespace eval ::skin {

	variable ContactListColors
	variable preview_skin_change 0

	##################################
	#  Colors Management Procedures  #
	##################################
	
	proc getColor {color {default ""}} {
		if { [info exists ::skin($color)] } {
			return [set ::skin($color)]
		} else {
			status_log "OOPS, trying to get a color that don't exists: $color\n" red
			return $default
		}
	}

	proc getContactListColor { state } {
		variable ContactListColors
		if { [info exists ContactListColors($state)] } {
			return [set ContactListColors($state)]
		} else {
			return ""
		}
	}

	proc setContactListColor { state color } {
		variable ContactListColors
		set ContactListColors($state) $color
	}


	proc setColor {color value} {
		set ::skin($color) $value
	}

	proc setDefaultColor {color value} {
		if { [info exists ::skin($color)] } {
			return [set ::skin($color)]
		} else {
			return [set ::skin($color) $value]
		}
	}
	
	##################################
	#  Settings Management Procedures  #
	##################################
	
	proc get {key {default ""}} {
		if { [info exists ::skin_setting($key)] } {
			return [::set ::skin_setting($key)]
		} else {
			status_log "OOPS, trying to get a setting that don't exists: $key\n" red
			return $default
		}
	}

	proc store {key value} {
		::set ::skin_setting($key) $value
	}
	
	
	proc InitSkinDefaults { } {
		variable ContactListColors
				
		global emoticon_number emotions emotions_names emotions_data
		set emoticon_number 0
		set emotions_names [list]
		if { [info exists emotions] } {unset emotions}
		if { [info exists emotions_data] } {unset emotions_data}
		if { [info exists ContactListColors] } {unset ContactListColors }

		store bigstate_xpad 0
		store bigstate_ypad 3
		
		store mystatus_xpad 5
		store mystatus_ypad 0
		
		store mailbox_xpad 5
		store mailbox_ypad 0
		
		store contract_xpad 5
		store contract_ypad 0
		
		store expand_xpad 5
		store expand_ypad 0
		
	}

	
	###############################
	# Standard Pixmaps
	###############################

	proc setPixmap {pixmap_name pixmap_file} {
		#Sets the image name - file name association,
		#but load on demand
		variable pixmap_names
		set pixmap_names($pixmap_name) $pixmap_file
	}
	
	#Check if the image was previously loaded, or we need to load
	#it. This way, the pixmaps will be loaded first time they're used,
	#on demand
	proc loadPixmap {image_name} {
	
		#Check if pixmap is already loaded
		variable loaded_pixmaps
		if { [info exists loaded_pixmaps($image_name)] } {
			return $loaded_pixmaps($image_name)
		}
		
		#Not loaded, so let's load it
		variable pixmap_names
		if { ! [info exists pixmap_names($image_name) ] } {
			return ""
		}

		set image_file $pixmap_names($image_name)
		set img [image create photo -file [GetSkinFile pixmaps $image_file] -format gif]
		set loaded_pixmaps($image_name) $img
	
		return $img
	}
	
	###############################
	# Smileys
	###############################
	
	#Set an association: smiley name - filename
	proc setSmiley { smiley_name filename } {
			
		variable smiley_names
		set smiley_names($smiley_name) $filename
		
	}
	
	#Load the given smiley, if not loaded already
	proc loadSmiley { smiley_name } {
	
		global tcl_platform
		variable loaded_smileys
		
		if { [info exists loaded_smileys($smiley_name)] } {
			return $loaded_smileys($smiley_name)
		}
		
		variable smiley_names
		set smiley_file $smiley_names($smiley_name)
		
		set imagename [image create photo -file [GetSkinFile smileys $smiley_file] -format gif]
		
		
		set loaded_smileys($smiley_name) $imagename
		return $imagename
	}
	
	
	###############################
	#Some special images!
	###############################
		
	proc getNoDisplayPicture { {skin_name ""} } {
		variable loaded_images
		if { [info exists loaded_images(no_pic)] } {
			return no_pic
		}
		image create photo no_pic -file [GetDisplayPicture nopic.gif $skin_name] -format gif
		set loaded_images(no_pic) 1
		return no_pic
	}
	
	#Special image for the colorbar right under your nick in the
	#contact list window
	proc getColorBar { {skin_name ""} } {
	
		#Get the contact list width
		global pgBuddy
		set width [expr {[winfo width $pgBuddy.text]} - 1 ]
		if { $width < 160 } {
			set width 160
		}
	
		#Delete old mainbar, and load colorbar
		#The colorbar will be loaded as follows:
		#[first 10 px][11th px repeating to fill][the rest of the colorbar]
		catch {image delete mainbar}
		
		set barheight [image height [loadPixmap colorbar]]
		set barwidth [image width [loadPixmap colorbar]]
		set barendwidth [expr $barwidth - 11]
		set barendstart [expr $width - $barendwidth]
	
		#Create the color bar copying from the pixmap
		image create photo mainbar -width $width -height $barheight
		mainbar blank
		mainbar copy [loadPixmap colorbar] -from 0 0 10 $barheight
		mainbar copy [loadPixmap colorbar] -from 10 0 11 $barheight -to 10 0 $barendstart $barheight
		mainbar copy [loadPixmap colorbar] -from [expr $barwidth - $barendwidth] 0 $barwidth $barheight -to $barendstart 0 $width $barheight
		
		return mainbar
	}
	
	###############################
	# Sounds
	###############################
	
	#Remember which sounds are loaded
	proc loadSound {sound_name} {
		variable loaded_sounds
		
		if { [info exists loaded_sounds($sound_name)] } {
			return snd_$sound_name
		}
		
		snack::sound snd_$sound_name -file [GetSkinFile sounds $sound_name]
		set loaded_sounds($sound_name) 1
		
		return snd_$sound_name
	}
	
	proc reloadSkin { skin_name } {

		reloadSkinSettings $skin_name
		
		#Reload all pixmaps
		variable loaded_pixmaps
		variable pixmap_names
		foreach name [array names loaded_pixmaps] {
			image create photo $loaded_pixmaps($name) -file [GetSkinFile pixmaps $pixmap_names($name) $skin_name] -format gif
		}
		
		#Reload smileys
		variable loaded_smileys
		variable smiley_names
		foreach name [array names loaded_smileys] {
			image create photo $loaded_smileys($name) -file [GetSkinFile smileys $smiley_names($name) $skin_name] -format gif
		}
		
		#Now reload special images that need special treatment
		variable loaded_images
		if {[info exists loaded_images(no_pic)]} {
			unset loaded_images(no_pic)
			getNoDisplayPicture $skin_name
		}
		if {[info exists loaded_images(colorbar)]} {
			unset loaded_images(colorbar)
			getColorBar $skin_name
		}
		
		#Reload sounds
		variable loaded_sounds
		foreach name [array names loaded_sounds] {
			snd_$name configure -file [GetSkinFile sounds $name]
		}
		
		#Change frame color
		#For All Platforms (except Mac)
		if {[catch {tk windowingsystem} wsystem] || $wsystem != "aqua"} {
			catch {.main configure -background [::skin::getColor mainwindowbg]}
		}
		
	}
		
	#######################################################################
	# Reload the given skin settings file
	proc reloadSkinSettings { skin_name } {
	
		#Set defaults
		InitSkinDefaults

		
	
		#Load smileys info from default skin first
		set skin_id [sxml::init [GetSkinFile "" settings.xml default]]
		sxml::register_routine $skin_id "skin:smileys:emoticon" ::smiley::newEmoticon
		sxml::register_routine $skin_id "skin:smileys:size" ::skin::SetEmoticonSize
		sxml::parse $skin_id
		sxml::end $skin_id
		
		#Then reload the real skin
		set skin_id [sxml::init [GetSkinFile "" settings.xml $skin_name]]
		
		if { $skin_id == -1 } {
			::amsn::errorMsg "[trans noskins]"
			exit
		}
		
		set ::loading_skin $skin_name
		sxml::register_routine $skin_id "skin:Description" skin_description
		sxml::register_routine $skin_id "skin:Colors" SetColors
		sxml::register_routine $skin_id "skin:ContactListColors" SetContactListColors
		sxml::register_routine $skin_id "skin:smileys:emoticon" ::smiley::newEmoticon
		sxml::register_routine $skin_id "skin:smileys:size" ::skin::SetEmoticonSize
		sxml::parse $skin_id
		sxml::end $skin_id
		unset ::loading_skin
				
		#Unimplemented yet
		#sxml::register_routine $skin_id "skin:WidgetOptions" ...
		#...

		#Destroy smiley selector so it's drawn again
		if { [winfo exists .smile_selector]} {destroy .smile_selector}
	
	}
	
	#######################################################################
	# Set the default emotion size for this skin
	proc SetEmoticonSize {cstack cdata saved_data cattr saved_attr args} {
		upvar $saved_data sdata
		
		
		if { [info exists sdata(${cstack}:smilew)] } { ::skin::store smilew [string trim $sdata(${cstack}:smilew)] }
		if { [info exists sdata(${cstack}:smileh)] } { ::skin::store smileh [string trim $sdata(${cstack}:smileh)] }
		
		return 0
	
	
	}
	
}

proc GetSkinFile { type filename {skin_override ""} } {
	global HOME2 HOME
	
	if { [catch { set skin "[::config::getGlobalKey skin]" } ] != 0 } {
		set skin "default"
	}
	
	if { $skin_override != "" } {
		set skin $skin_override
	}
	set defaultskin "default"
	
	
	#Get file using global path
	if { "[string range $filename 0 0]" == "/" && [file readable  $filename] } {
		return "$filename"
	#Get file from program dir skins folder
	} elseif { [file readable [file join [set ::program_dir] skins $skin $type $filename]] } {
		return "[file join [set ::program_dir] skins $skin $type $filename]"
	#Get file from ~/.amsn/skins folder
	} elseif { [file readable [file join $HOME2 skins $skin $type $filename]] } {
		return "[file join $HOME2 skins $skin $type $filename]"
	#Get file from ~/.amsn/profile/skins folder
	} elseif { [file readable [file join $HOME skins $skin $type $filename]] } {
		return "[file join $HOME skins $skin $type $filename]"
	#Get file from default skin
	} elseif { [file readable [file join [set ::program_dir] skins $defaultskin $type $filename]] } {
		return "[file join [set ::program_dir] skins $defaultskin $type $filename]"
	} else {
	#	status_log "File [file join  [set ::program_dir]skins $skin $type $filename] not found!!!\n"
		return "[file join [set ::program_dir] skins $defaultskin $type null]"
	}
	
}

proc GetDisplayPicture { filename {skin_override ""}} {
	global HOME2 HOME
	
	if { [catch { set skin "[::config::getGlobalKey skin]" } ] != 0 } {
		set skin "default"
	}
	
	set defaultskin "default"
		
	#Get file using global path
	if { "[string range $filename 0 0]" == "/" && [file readable  $filename] } {
		return "$filename"
	#Get from personal display pics
	} elseif { [file readable [file join $HOME displaypic $filename]] } {
		return "[file join $HOME displaypic $filename]"
	#Get file from program dir skins folder
	} elseif { [file readable [file join [set ::program_dir] skins $skin displaypic $filename]] } {
		return "[file join [set ::program_dir] skins $skin displaypic $filename]"
	#Get file from ~/.amsn/skins folder
	} elseif { [file readable [file join $HOME2 skins $skin displaypic $filename]] } {
		return "[file join $HOME2 skins $skin displaypic $filename]"
	#Get file from ~/.amsn/profile/skins folder
	} elseif { [file readable [file join $HOME skins $skin displaypic $filename]] } {
		return "[file join $HOME skins $skin displaypic $filename]"
	#Get file from default skin
	} elseif { [file readable [file join [set ::program_dir] skins $defaultskin displaypic $filename]] } {
		return "[file join [set ::program_dir] skins $defaultskin displaypic $filename]"
	} else {
	#	status_log "File [file join  [set ::program_dir]skins $skin displaypic $filename] not found!!!\n"
		return "[file join [set ::program_dir] skins $defaultskin displaypic null]"
	}
	
}



proc skin_description {cstack cdata saved_data cattr saved_attr args} {
    global skin

    set skin(description) [string trim "$cdata"]
    return 0
}

proc findskins { } {
	global HOME HOME2

	set skins [glob -directory skins */settings.xml]
	set skins_in_home [glob -nocomplain -directory [file join $HOME skins] */settings.xml]
    	set skins_in_home2 [glob -nocomplain -directory [file join $HOME2 skins] */settings.xml]

	set skins [concat $skins $skins_in_home $skins_in_home2]


	set skinlist [list]

	foreach skin $skins {
		set dir [file dirname $skin]
		set desc ""

		if { [file readable [file join $dir desc.txt] ] } {
			set fd [open [file join $dir desc.txt]]
			set desc [string trim [read $fd]]
			close $fd
		}

		set lastslash [expr {[string last "/" $dir]+1}]
		set skinname [string range $dir $lastslash end]
		lappend skinname $desc
		lappend skinlist $skinname
	}
    
	return $skinlist
}

proc SelectSkinGui { } {
	set w .skin_selector

	if { [winfo exists $w] } {
		focus $w
		raise $w
		return
	}
	toplevel $w
	wm resizable $w 0 0
	wm title $w "[trans chooseskin]"
	wm geometry $w +100+100

	label $w.choose -text "[trans chooseskin]" -font bboldf
	pack $w.choose -side top
    
	frame $w.main -relief solid -borderwidth 2
	frame $w.main.left -relief flat
	frame $w.main.right -relief flat
	frame $w.main.left.images -relief flat
	text $w.main.left.desc -height 6 -width 40 -relief flat -background [::skin::getColor mainwindowbg] -font sboldf -wrap word
	listbox $w.main.right.box -yscrollcommand "$w.main.right.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0  -height 8 -width 30
	scrollbar $w.main.right.ys -command "$w.main.right.box yview" -highlightthickness 0 \
	-borderwidth 1 -elementborderwidth 2

	bind $w <<Escape>> "selectskincancel $w"
	pack $w.main.left.images -in $w.main.left -side top -expand 0 -fill both
	pack $w.main.left.desc -in $w.main.left -side bottom -expand 1 -fill both
	pack $w.main.left -in $w.main -side left -expand 1 -fill both
	pack $w.main.right.ys -side right -fill both
	pack $w.main.right.box -side left -expand 0 -fill both
	pack $w.main.right -side right -expand 1 -fill both
	pack $w.main -expand 1 -fill both

	label $w.status -text ""
	pack $w.status -side bottom

	image create photo blank -width 1 -height 75
	label $w.main.left.images.blank -image blank

	image create photo blank2 -width 400 -height 1
	label $w.main.left.images.blank2 -image blank2

	set select -1
	set idx 0

	button $w.ok -text "[trans ok]" -command "selectskinok $w" 
	button $w.cancel -text "[trans cancel]" -command "selectskincancel $w" 
	checkbutton $w.preview -text "[trans preview]" -variable ::skin::preview_skin_change -onvalue 1 -offvalue 0

	pack $w.ok  $w.cancel $w.preview -side right -pady 5 -padx 5

	set the_skins [findskins]

	foreach skin $the_skins {
		if { [lindex $skin 0] == [::config::getGlobalKey skin] } { set select $idx } 
		$w.main.right.box insert end "[lindex $skin 0]"
		incr idx
	}

	set ::skin::skin_reloaded_needs_reset 0
	if { $select == -1 } {
		set select 0
		status_log "selecy = 0 --- didn't find current skin defaulting to first"
		
		$w.main.right.box selection set $select
 		$w.main.right.box itemconfigure $select -background #AAAAAA

		set currentskin [lindex [lindex $the_skins 0] 0]
		if { $::skin::preview_skin_change == 1 } {
			set ::skin::skin_reloaded_needs_reset 1
			::skin::reloadSkin $currentskin
		}
	} else {
		status_log "select = $select --- [::config::getGlobalKey skin]\n"

		$w.main.right.box selection set $select
		$w.main.right.box itemconfigure $select -background #AAAAAA
	}
		
	applychanges 1
	bind $w <Destroy> "grab release $w"
	bind $w.main.right.box <Button1-ButtonRelease> "applychanges"

	moveinscreen $w 30
}

proc applychanges { {skip_reload 0} } {
	set w .skin_selector
	
	set the_skins [findskins]

	set currentskin [lindex [lindex $the_skins [$w.main.right.box curselection]] 0]
	set currentdesc [lindex [lindex $the_skins [$w.main.right.box curselection]] 1]

	clear_exampleimg

	# If our skin hasn't the example images, take them from the default one
	image create photo preview1 -file [GetSkinFile pixmaps prefpers.gif $currentskin] -format gif
	image create photo preview2 -file [GetSkinFile pixmaps bonline.gif $currentskin] -format gif
	image create photo preview3 -file [GetSkinFile pixmaps offline.gif $currentskin] -format gif
	image create photo preview4 -file [GetSkinFile pixmaps baway.gif $currentskin] -format gif
	image create photo preview5 -file [GetSkinFile pixmaps amsnicon.gif $currentskin] -format gif
	image create photo preview6 -file [GetSkinFile pixmaps butblock.gif $currentskin] -format gif
	image create photo preview7 -file [GetSkinFile pixmaps butsmile.gif $currentskin] -format gif
	image create photo preview8 -file [GetSkinFile pixmaps butsend.gif $currentskin] -format gif
	
	label $w.main.left.images.1 -image preview1
	label $w.main.left.images.2 -image preview2
	label $w.main.left.images.3 -image preview3
	label $w.main.left.images.4 -image preview4
	label $w.main.left.images.5 -image preview5
	label $w.main.left.images.6 -image preview6
	label $w.main.left.images.7 -image preview7
	label $w.main.left.images.8 -image preview8
	grid $w.main.left.images.1 -in $w.main.left.images -row 1 -column 1
	grid $w.main.left.images.2 -in $w.main.left.images -row 1 -column 2
	grid $w.main.left.images.3 -in $w.main.left.images -row 1 -column 3
	grid $w.main.left.images.4 -in $w.main.left.images -row 1 -column 4
	grid $w.main.left.images.5 -in $w.main.left.images -row 1 -column 5
	grid $w.main.left.images.6 -in $w.main.left.images -row 1 -column 6
	grid $w.main.left.images.7 -in $w.main.left.images -row 1 -column 7
	grid $w.main.left.images.8 -in $w.main.left.images -row 1 -column 8

	grid $w.main.left.images.blank -in $w.main.left.images -row 1 -column 10
	grid $w.main.left.images.blank2 -in $w.main.left.images -row 2 -column 1 -columnspan 8

	$w.main.left.desc configure -state normal
	$w.main.left.desc delete 0.0 end
	$w.main.left.desc insert end "[trans description]\n\n$currentdesc"
	$w.main.left.desc configure -state disabled
	
	if { (!$skip_reload) && $::skin::preview_skin_change == 1 } {
		set ::skin::skin_reloaded_needs_reset 1
		::skin::reloadSkin $currentskin
	}
}

proc clear_exampleimg { } {
	if {[winfo exists .skin_selector.main.left.images]} {
		destroy .skin_selector.main.left.images.1
		destroy .skin_selector.main.left.images.2
		destroy .skin_selector.main.left.images.3
		destroy .skin_selector.main.left.images.4
		destroy .skin_selector.main.left.images.5
		destroy .skin_selector.main.left.images.6
		destroy .skin_selector.main.left.images.7
		destroy .skin_selector.main.left.images.8
		
		#frame .skin_selector.main.left.images -relief flat
		#pack .skin_selector.main.left.images -in .skin_selector.main.left -side top -expand 1 -fill both
	}
}

proc selectskinok { w } {

	if { [$w.main.right.box curselection] == "" } {
		$w.status configure -text "[trans selectskin]"
	}  else {
	
	$w.status configure -text ""

	set skinidx [$w.main.right.box curselection]

	set skin [lindex [lindex [findskins] $skinidx] 0]
	status_log "Chose skin No $skinidx : $skin\n"
	config::setGlobalKey skin $skin
	save_config
	::config::saveGlobal
	unset ::skin::skin_reloaded_needs_reset
	::skin::reloadSkin $skin
	#msg_box [trans mustrestart]

	destroy $w
    }
}

proc selectskincancel { w } {
	if { $::skin::skin_reloaded_needs_reset } {
		::skin::reloadSkin [::config::getGlobalKey skin]
	}
	unset ::skin::skin_reloaded_needs_reset
	destroy $w
}


proc SetColors {cstack cdata saved_data cattr saved_attr args} {
    upvar $saved_data sdata
        
    if { [info exists sdata(${cstack}:mainwindowbg)] } { ::skin::setColor mainwindowbg [string trim $sdata(${cstack}:mainwindowbg)] }
    if { [info exists sdata(${cstack}:chatwindowbg)] } { ::skin::setColor chatwindowbg [string trim $sdata(${cstack}:chatwindowbg)] }
    #Don't use buttonbarbg on Mac OS X and put 0 value to chatborders
    if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
    	if { [info exists sdata(${cstack}:chatwindowbg)] } { ::skin::setColor buttonbarbg [string trim $sdata(${cstack}:chatwindowbg)] }
    	if { [info exists sdata(${cstack}:chat_top_border)] } { ::skin::setColor chat_top_border 0 }
	if { [info exists sdata(${cstack}:chat_output_border)] } { ::skin::setColor chat_output_border 0 }
	if { [info exists sdata(${cstack}:chat_buttons_border)] } { ::skin::setColor chat_buttons_border 0 }
	if { [info exists sdata(${cstack}:chat_input_border)] } { ::skin::setColor chat_input_border 0 }
	if { [info exists sdata(${cstack}:chat_status_border)] } { ::skin::setColor chat_status_border 0 }
    } else {
    	if { [info exists sdata(${cstack}:buttonbarbg)] } { ::skin::setColor buttonbarbg [string trim $sdata(${cstack}:buttonbarbg)] }
    	if { [info exists sdata(${cstack}:chatborders)] } { ::skin::setColor chatborders [string trim $sdata(${cstack}:chatborders)] }
    }
    if { [info exists sdata(${cstack}:topbarbg)] } { ::skin::setColor topbarbg [string trim $sdata(${cstack}:topbarbg)] }
    if { [info exists sdata(${cstack}:topbartext)] } { ::skin::setColor topbartext [string trim $sdata(${cstack}:topbartext)] }
    if { [info exists sdata(${cstack}:menubgcolor)] } { ::skin::setColor menubackground [string trim $sdata(${cstack}:menubgcolor)] }
    if { [info exists sdata(${cstack}:menufgcolor)] } { ::skin::setColor menuforeground [string trim $sdata(${cstack}:menufgcolor)] }
    if { [info exists sdata(${cstack}:menuactivebgcolor)] } { ::skin::setColor menuactivebackground [string trim $sdata(${cstack}:menuactivebgcolor)] }
    if { [info exists sdata(${cstack}:menuactivefgcolor)] } { ::skin::setColor menuactiveforeground [string trim $sdata(${cstack}:menuactivefgcolor)] }
    if { [info exists sdata(${cstack}:balloontextcolor)] } { ::skin::setColor balloontext [string trim $sdata(${cstack}:balloontextcolor)] }
    if { [info exists sdata(${cstack}:balloonbgcolor)] } { ::skin::setColor balloonbackground [string trim $sdata(${cstack}:balloonbgcolor)] }
    if { [info exists sdata(${cstack}:balloonbordercolor)] } { ::skin::setColor balloonborder [string trim $sdata(${cstack}:balloonbordercolor)] }
    
    if { [info exists sdata(${cstack}:chat_top_padx)] } { ::skin::setColor chat_top_padx [string trim $sdata(${cstack}:chat_top_padx)] }
    if { [info exists sdata(${cstack}:chat_top_pady)] } { ::skin::setColor chat_top_pady [string trim $sdata(${cstack}:chat_top_pady)] }
    if { [info exists sdata(${cstack}:chat_paned_padx)] } { ::skin::setColor chat_paned_padx [string trim $sdata(${cstack}:chat_paned_padx)] }
    if { [info exists sdata(${cstack}:chat_paned_pady)] } { ::skin::setColor chat_paned_pady [string trim $sdata(${cstack}:chat_paned_pady)] }
    if { [info exists sdata(${cstack}:chat_buttons_padx)] } { ::skin::setColor chat_buttons_padx [string trim $sdata(${cstack}:chat_buttons_padx)] }
    if { [info exists sdata(${cstack}:chat_buttons_pady)] } { ::skin::setColor chat_buttons_pady [string trim $sdata(${cstack}:chat_buttons_pady)] }
    if { [info exists sdata(${cstack}:chat_status_padx)] } { ::skin::setColor chat_status_padx [string trim $sdata(${cstack}:chat_status_padx)] }
    if { [info exists sdata(${cstack}:chat_status_pady)] } { ::skin::setColor chat_status_pady [string trim $sdata(${cstack}:chat_status_pady)] }
    if { [info exists sdata(${cstack}:chat_input_padx)] } { ::skin::setColor chat_input_padx [string trim $sdata(${cstack}:chat_input_padx)] }
    if { [info exists sdata(${cstack}:chat_input_pady)] } { ::skin::setColor chat_input_pady [string trim $sdata(${cstack}:chat_input_pady)] }
    if { [info exists sdata(${cstack}:chat_dp_padx)] } { ::skin::setColor chat_dp_padx [string trim $sdata(${cstack}:chat_dp_padx)] }
    if { [info exists sdata(${cstack}:chat_dp_pady)] } { ::skin::setColor chat_dp_pady [string trim $sdata(${cstack}:chat_dp_pady)] }
    if { [info exists sdata(${cstack}:chat_leftframe_padx)] } { ::skin::setColor chat_leftframe_padx [string trim $sdata(${cstack}:chat_leftframe_padx)] }
    if { [info exists sdata(${cstack}:chat_leftframe_pady)] } { ::skin::setColor chat_leftframe_pady [string trim $sdata(${cstack}:chat_leftframe_pady)] }
    if { [info exists sdata(${cstack}:chat_sendbutton_padx)] } { ::skin::setColor chat_sendbutton_padx [string trim $sdata(${cstack}:chat_sendbutton_padx)] }
    if { [info exists sdata(${cstack}:chat_sendbutton_pady)] } { ::skin::setColor chat_sendbutton_pady [string trim $sdata(${cstack}:chat_sendbutton_pady)] }

    if { [info exists sdata(${cstack}:chat_top_border)] } { ::skin::setColor chat_top_border [string trim $sdata(${cstack}:chat_top_border)] }
    if { [info exists sdata(${cstack}:chat_output_border)] } { ::skin::setColor chat_output_border [string trim $sdata(${cstack}:chat_output_border)] }
    if { [info exists sdata(${cstack}:chat_buttons_border)] } { ::skin::setColor chat_buttons_border [string trim $sdata(${cstack}:chat_buttons_border)] }
    if { [info exists sdata(${cstack}:chat_input_border)] } { ::skin::setColor chat_input_border [string trim $sdata(${cstack}:chat_input_border)] }
if { [info exists sdata(${cstack}:chat_status_border)] } { ::skin::setColor chat_status_border [string trim $sdata(${cstack}:chat_status_border)] }
    
    if { [info exists sdata(${cstack}:statusbarbg)] } { ::skin::setColor statusbarbg [string trim $sdata(${cstack}:statusbarbg)] }
    if { [info exists sdata(${cstack}:statusbartext)] } { ::skin::setColor statusbartext [string trim $sdata(${cstack}:statusbartext)] }
    return 0
}


proc SetContactListColors {cstack cdata saved_data cattr saved_attr args} {
    upvar $saved_data sdata
    
    if { [info exists sdata(${cstack}:online)] } { ::skin::setContactListColor online [string trim $sdata(${cstack}:online)] }
    if { [info exists sdata(${cstack}:noactivity)] } { ::skin::setContactListColor noactivity [string trim $sdata(${cstack}:noactivity)] }
    if { [info exists sdata(${cstack}:rightback)] } { ::skin::setContactListColor rightback [string trim $sdata(${cstack}:rightback)] }
    if { [info exists sdata(${cstack}:onphone)] } { ::skin::setContactListColor onphone [string trim $sdata(${cstack}:onphone)] }
    if { [info exists sdata(${cstack}:busy)] } { ::skin::setContactListColor busy [string trim $sdata(${cstack}:busy)] }
    if { [info exists sdata(${cstack}:away)] } { ::skin::setContactListColor away [string trim $sdata(${cstack}:away)] }
    if { [info exists sdata(${cstack}:gonelunch)] } { ::skin::setContactListColor gonelunch [string trim $sdata(${cstack}:gonelunch)] }
    if { [info exists sdata(${cstack}:appearoff)] } { ::skin::setContactListColor appearoff [string trim $sdata(${cstack}:appearoff)] }
    if { [info exists sdata(${cstack}:offline)] } { ::skin::setContactListColor offline [string trim $sdata(${cstack}:offline)] }
    return 0
}



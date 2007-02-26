package require contentmanager

snit::widgetadaptor loginscreen {

	variable background_tag

	component dp_label
	variable dp_label_tag

	component user_label
	component user_field
	variable user_field_tag

	component pass_label
	component pass_field
	variable pass_field_tag

	component status_label
	component status_field
	variable status_field_tag

	component rem_me_field
	component rem_pass_field
	component auto_login_field

	component login_button
	variable login_button_tag

	component forgot_pass_link
	component service_status_link
	component new_account_link

	variable remember_me

	delegate method * to hull except {SortElements PopulateStateList LoginButtonPressed CanvasTextToLink LinkClicked}

	constructor { args } {
		set remember_me 0

		installhull using canvas -bg white -highlightthickness 0 -xscrollcommand "$self CanvasScrolled" -yscrollcommand "$self CanvasScrolled"

		# Create background image
		set background_tag [$self create image 0 0 -anchor se -image [::skin::loadPixmap back]]

		# Create framework for elements
		contentmanager add group main			-orient vertical	-widget $self
		contentmanager add group main lang		-orient horizontal	-widget $self
		contentmanager add group main dp		-orient horizontal	-widget $self	-align center
		contentmanager add group main user		-orient vertical	-widget $self
		contentmanager add group main pass		-orient vertical	-widget $self
		contentmanager add group main status		-orient vertical	-widget $self
		contentmanager add group main rem_me		-orient horizontal	-widget $self
		contentmanager add group main rem_pass		-orient horizontal	-widget $self
		contentmanager add group main auto_login	-orient horizontal	-widget $self
		contentmanager add group main login		-orient horizontal	-widget $self	-align center
		contentmanager add group main links		-orient vertical	-pady 25	-widget $self	-align center

		# Create widgets
		# Display picture
		set dp_label [label $self.dp -image [::skin::getDisplayPicture ""] -borderwidth 1 -highlightthickness 0 -relief solid]
		set dp_label_tag [$self create window 0 0 -anchor nw -window $dp_label]
		# Username
		set user_label_tag [$self create text 0 0 -anchor nw -text [trans user]]
		set user_field [combobox::combobox $self.user -editable true -bg white -relief solid -width 25 -command "$self UserSelected"]
		set user_field_tag [$self create window 0 0 -anchor nw -window $user_field]
		# Populate user list
		set tmp_list ""
		$user_field list delete 0 end
		set idx 0
		while { [LoginList get $idx] != 0 } {
			lappend tmp_list [LoginList get $idx]
			incr idx
		}
		eval $user_field list insert end $tmp_list
		# Password
		set pass_label_tag [$self create text 0 0 -anchor nw -text [trans pass]]
		set pass_field [entry $self.pass -show "*" -bg white -relief solid -width 25]
		set pass_field_tag [$self create window 0 0 -anchor nw -window $pass_field]
		# Status
		set status_label_tag [$self create text 0 0 -anchor nw -text [trans signinstatus]]
		set status_field [combobox::combobox $self.status -editable true -bg white -relief solid -width 25]
		set status_field_tag [$self create window 0 0 -anchor nw -window $status_field]
		# Populate status list
		$self PopulateStateList
		# Options
		# Remember me
		set rem_me_label_tag [$self create text 0 0 -anchor nw -text [trans remember_me]]
		set rem_me_field [checkbutton $self.rem_me -variable [myvar remember_me] -bg white]
		set rem_me_field_tag [$self create window 0 0 -anchor nw -window $rem_me_field]
		# Remember password
		set rem_pass_label_tag [$self create text 0 0 -anchor nw -text [trans rememberpass]]
		set rem_pass_field [checkbutton $self.rem_pass -variable [::config::getVar save_password] -bg white]
		set rem_pass_field_tag [$self create window 0 0 -anchor nw -window $rem_pass_field]
		# Log in automatically
		set auto_login_label_tag [$self create text 0 0 -anchor nw -text [trans autoconnect]]
		set auto_login_field [checkbutton $self.auto_login -variable [::config::getVar autoconnect] -bg white]

		set auto_login_field_tag [$self create window 0 0 -anchor nw -window $auto_login_field]
		# Login button
		set login_button [button $self.login -text [trans login] -command "$self LoginButtonPressed"]
		set login_button_tag [$self create window 0 0 -anchor nw -window $login_button]
		# Useful links
		# Forgot password
		set forgot_pass_link [$self create text 0 0 -anchor nw -text [trans forgot_pass]]
		# Service status
		set service_status_link [$self create text 0 0 -anchor nw -text [trans msnstatus]]
		# New account
		set new_account_link [$self create text 0 0 -anchor nw -text [trans new_account]]

		# Place widgets in framework
		# Display picture
		contentmanager add element main dp label -widget $self -tag $dp_label_tag
		# Username
		contentmanager add element main user label -widget $self -tag $user_label_tag
		contentmanager add element main user field -widget $self -tag $user_field_tag
		# Password
		contentmanager add element main pass label -widget $self -tag $pass_label_tag
		contentmanager add element main pass field -widget $self -tag $pass_field_tag
		# Status
		contentmanager add element main status label -widget $self -tag $status_label_tag
		contentmanager add element main status field -widget $self -tag $status_field_tag
		# Options
		contentmanager add element main rem_me field -widget $self -tag $rem_me_field_tag
		contentmanager add element main rem_me label -widget $self -tag $rem_me_label_tag
		contentmanager add element main rem_pass field -widget $self -tag $rem_pass_field_tag
		contentmanager add element main rem_pass label -widget $self -tag $rem_pass_label_tag
		contentmanager add element main auto_login field -widget $self -tag $auto_login_field_tag
		contentmanager add element main auto_login label -widget $self -tag $auto_login_label_tag
		# Login button
		contentmanager add element main login login_button -widget $self -tag $login_button_tag
		# Links
		contentmanager add element main links forgot_pass -widget $self -tag $forgot_pass_link -pady 2
		contentmanager add element main links service_status -widget $self -tag $service_status_link -pady 2
		contentmanager add element main links new_account -widget $self -tag $new_account_link -pady 2
		# Make the text items into links
		$self CanvasTextToLink main links forgot_pass [list launch_browser "https://accountservices.passport.net/uiresetpw.srf?lc=1033"]
		$self CanvasTextToLink main links service_status [list launch_browser "http://messenger.msn.com/Status.aspx"]
		$self CanvasTextToLink main links new_account [list launch_browser "https://accountservices.passport.net/reg.srf?sl=1&lc=1033"]

		# Set font for canvas all text items
		set all_tags [$self find all]
		foreach tag $all_tags {
			if { [$self type $tag] == "text" } {
				$self itemconfigure $tag -font splainf
			}
		}

		# Bindings
		bind $user_field <KeyRelease> "+after cancel [list $self UsernameEdited]; after 1 [list $self UsernameEdited]"
		bind $self <Map> "$self Resized"
		bind $self <Configure> "$self Resized"
	}

	# Called when canvas is resized
	method Resized {} {
		# Keep background in bottom right corner
		$self AutoPositionBackground
		# Arrange items on the canvas
		$self SortElements
	}

	method CanvasScrolled { args } {
		# Keep background in bottom right corner
		$self AutoPositionBackground
	}

	method AutoPositionBackground {} {
		set bg_x [expr {[winfo width $self] - 5}]
		set bg_y [expr {[winfo height $self] - 5}]
		$self coords $background_tag [$self canvasx $bg_x] [$self canvasy $bg_y]
	}

	method CanvasTextToLink { args } {
		set tree [lrange $args 0 end-1]
		set cmd [list [lindex $args end]]
		set canvas_tag [eval contentmanager cget $tree -tag]
		eval contentmanager bind $tree <Enter> [list "$self configure -cursor hand2"]
		eval contentmanager bind $tree <Leave> [list "$self configure -cursor left_ptr"]
		eval contentmanager bind $tree <ButtonRelease-1> [list "$self LinkClicked $canvas_tag %x %y $cmd"]
		$self itemconfigure $canvas_tag -fill blue
	}

	method LinkClicked { tag x y cmd } {
		# Convert x and y to actual canvas coords, in case we've scrolled.
		set x [$self canvasx $x]
		set y [$self canvasy $y]

		set item_coords [$self bbox $tag]

		if { $x > [lindex $item_coords 0] && $x < [lindex $item_coords 2] && $y > [lindex $item_coords 1] && $y < [lindex $item_coords 3] } {
			eval $cmd
		}
	}

	method PopulateStateList {} {
		# Make the list editable
		$status_field configure -editable true
		# Standard states
		$status_field list delete 0 end
		set i 0
		while { $i < 8 } {
			set statecode "[::MSN::numberToState $i]"
			set description "[trans [::MSN::stateToDescription $statecode]]"
			$status_field list insert end $description
			incr i
		}
		# Custom states
		AddStatesToList $status_field
		# Make it non-editable
		$status_field configure -editable false
		# Select remembered state
		$status_field select [get_state_list_idx [::config::getKey connectas]]
	}

	method SortElements {} {
		contentmanager sort main -level r
		set main_x [expr {([winfo width $self] / 2) - ([contentmanager width main] / 2)}]
		set main_y 25
		contentmanager coords main $main_x $main_y
	}

	method UsernameEdited {} {
		# Get username
		set username [$user_field get]
		# Check if the username has a profile.
		# If it does, switch to it, select the remember me box and set the DP.
		# If it doesn't, deselect the remember me box and set the DP to generic 'nopic' DP
		if { [LoginList exists 0 $username] } {
			$self UserSelected $user_field $username
		} else {
			$rem_me_field deselect
			$rem_me_field configure -state normal
			$dp_label configure -image [::skin::getDisplayPicture $username]
		}
	}

	method UserSelected { combo user } {
		# We have to check whether this profile exists because sometimes userSelected gets called when it shouldn't,
		# e.g when tab is pressed in the username combobox
		if { [LoginList exists 0 $user] } {
			# Select and disable 'remember me' checkbutton
			$rem_me_field select
			$rem_me_field configure -state disabled
			# Switch to this profile
			ConfigChange $combo $user
			# Get states
			$self PopulateStateList
			# Change DP
			$dp_label configure -image displaypicture_std_self
			# If we've remembered the password, insert it, if not, clear the password field
			if { [set [$rem_pass_field cget -variable]] } {
				global password
				$pass_field delete 0 end
				$pass_field insert end $password
			} else {
				$pass_field delete 0 end
			}
			# Re-sort stuff on canvas (in case, for example, we now have a larger/smaller DP)
			# The 'after 100' is because the status combobox doesn't seem to regain it's height immediately for some
			# reason, so if we sort straight away, the checkbox below the status combo overlaps it.
			after 100 "$self SortElements"
		}
	}

	method LoginButtonPressed { } {
		# Get user and pass
		set user [$user_field get]
		set pass [$pass_field get]
	
		# Check we actually have a username and password entered!
		if { $user == "" || $pass == "" } { return }
	
		# If remember me checkbutton is selected and a profile doesn't already exists for this user, create a profile for them.
		if { $remember_me && ![LoginList exists 0 $user] } {
			CreateProfile $user
		}
	
		# Login with them
		$self login $user $pass
	}

	method login { user pass } {
		global password

		# Set username and password key and global repsectively
		set password $pass
		::config::setKey login $user

		# Connect
		::MSN::connect $password

		# TEMPORARY CODE TO SWITCH BACK TO WIDGET WITH LOGIN PROGRESS IN
		pack forget $self
		destroy .l
		pack .main -e 1 -f both
	}
}

pack forget .main
pack [loginscreen .l] -e 1 -f both
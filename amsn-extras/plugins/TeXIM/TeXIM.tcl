# Copyright Andrei Barbu (abarbu@uwaterloo.ca)
# This code is distributed under the GPL


namespace eval ::TeXIM {

	# We do this so more than one person can use amsn and this plugin concurrently
	# Otherwise we would risk simultaneous access to the same file
	variable localpid [pid]
	variable dir /tmp/${localpid}-latex

	proc Init { dir } {
		plugins_log "TeXIM" "LaTeX plugin has started"

		file mkdir $::TeXIM::dir

		::plugins::RegisterPlugin "TeXIM"
		::plugins::RegisterEvent "TeXIM" WinWrite parseLaTeX	

		#TODO, fix amsn string support, it doesn't put it by default to what it sais in config
		#TODO, add a multiline input box for header and footer

                array set ::TeXIM::config {
			showtex {0}
			showerror {0}
			path_latex {latex}
			path_dvips {dvips}
			path_convert {convert}
			dummy {0}
	        }
		
	        set ::TeXIM::configlist [list \
					     [list bool "Show tex" showtex] \
					     [list bool "Display errors" showerror] \
					     [list str "Path to latex binary" path_latex] \
					     [list str "Path to dvips binary" path_dvips] \
					     [list str "Path to convert binary" path_convert] \
					    ]
	}
	
	proc DeInit { } {
		file delete -force $::TeXIM::dir
	}
	
	proc parseLaTeX {event evPar} {

		upvar 2 txt txt
		upvar 2 win_name win_name

		if { [string first "\\tex " $txt] == 0 } { 
			
			# Strip \tex out
			set msg [string range $txt 4 end]
			
			set localtime [clock seconds]

			set chan [open ${::TeXIM::dir}/temp.tex w]
			puts $chan "\\documentclass\[10pt\]\{article\}"
			puts $chan "\\pagestyle{empty}"
			puts $chan "\\begin\{document\}"
			puts $chan "\\begin\{huge\}"
			puts $chan $msg
			puts $chan "\\end\{huge\}"
			puts $chan "\\end\{document\}"
			flush $chan
			close $chan

			set olddir [pwd]
			cd ${::TeXIM::dir}

			catch { exec $::TeXIM::config(path_latex)  \
				    -interaction=nonstopmode ${::TeXIM::dir}/temp.tex } msg

			if { [file exists ${::TeXIM::dir}/temp.dvi] }  {
				if { [ catch { exec $::TeXIM::config(path_dvips) \
						   -f -E -o ${::TeXIM::dir}/temp.ps -q ${::TeXIM::dir}/temp.dvi } msg ] == 0 } { 
					catch {file delete ${::TeXIM::dir}/temp.dvi}
					if { [ catch { exec $::TeXIM::config(path_convert) \
							   ${::TeXIM::dir}/temp.ps ${::TeXIM::dir}/temp.gif } msg ] == 0 } {

						set chatid [::ChatWindow::Name $win_name]
						set sb [::MSN::SBFor $chatid]
						SendInk $sb ${::TeXIM::dir}/temp.gif

						set imagename [image create photo -file ${::TeXIM::dir}/temp.gif -format gif]
						
						${win_name}.f.out.text configure -state normal -font bplainf -foreground black
						${win_name}.f.out.text image create end -name ${localtime} -image $imagename -padx 0 -pady 0 
						
						if { $::TeXIM::config(showtex) == 0 } { 
							set txt "" 
						} else {
							${win_name}.f.out.text configure -state normal -font bplainf -foreground black
							${win_name}.f.out.text insert end "\n"
						}		    
						
						cd $olddir
						return txt
					}
				}
				
			}

			catch {file delete ${::TeXIM::dir}/temp.dvi}

			if { $::TeXIM::config(showerror) == 1 } {
				${win_name}.f.out.text insert end $msg
				${win_name}.f.out.text insert end "\n"
			} else { plugins_log "TeXIM" $msg }  
		
		
			cd $olddir
			return txt	
		}
		
		return ""
	}


	proc SendInk { sb  file } {

		set maxchars 800
		set fd [open $file r]
		fconfigure $fd -translation {binary binary}
		set data [read $fd]

		set data [::base64::encode $data]
		set data [string map { "\n" ""} $data]

		set chunks [expr int( [string length $data] / $maxchars) + 1]


		plugins_log "TeXIM" "data : $data\nchunks : $chunks\n"

		for {set i 0 } { $i < $chunks } { incr i } {
			set chunk [string range $data [expr $i * $maxchars] [expr ($i * $maxchars) + $maxchars - 1]]
			set msg "MIME-Version: 1.0\r\nContent-Type: application/x-ms-ink"
			if { $i == 0 } {
				set chunk "base64:$chunk"
				if { $chunks == 1 } {
					set msg "$msg\r\n\r\n$chunk"
				} else { 
					set msgid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
					set msg "$msg\r\nMessage-ID: \{$msgid\}\r\nChunks: $chunks\r\n\r\n$chunk"
				}
			} else {
				set msg "$msg\r\nMessage-ID: \{$msgid\}\r\nChunk: $i\r\n\r\n$chunk"
			}
			set msglen [string length $msg]

			::MSN::WriteSBNoNL $sb "MSG" "U $msglen\r\n$msg"
			
		}
		

	}

}

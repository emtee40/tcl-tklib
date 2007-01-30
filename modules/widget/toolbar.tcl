# -*- tcl -*-
#
# toolbar - /snit::widget
#	Manage items in a toolbar.
#
# RCS: @(#) $Id: toolbar.tcl,v 1.9 2007/01/30 21:45:13 andreas_kupries Exp $
#

#  ## Padding can be a list of {padx pady}
#  -ipad -default 1 ; provides padding around each status bar item
#  -pad  -default 0 ; provides general padding around the status bar
#  -separator -default {} ; one of {top left bottom right {}}
#
#  All other options to frame
#
# Methods
#  $path getframe           => $frame
#  $path add $widget ?args? => $widget
#  All other methods to frame
#
# Bindings
#  NONE
#

if 0 {
    # Example
    lappend auto_path ~/cvs/tcllib/tklib/modules/widget

    package require widget::toolbar
    set f [ttk::frame .f -padding 4]
    pack $f -fill both -expand 1
    set tb [widget::toolbar .f.tb]
    pack $tb -fill both -expand 1
    $tb add button foo -text Foo
    $tb add button bar -text Bar -separator 1
    $tb add button baz -text Baz
    set b [ttk::button $tb.zippy -text Zippy -state disabled]
    $tb add $b
}

package require widget
package require tile
#package require tooltip

snit::widget widget::toolbar {
    hulltype ttk::frame

    component separator
    component frame

    delegate option * to hull
    delegate method * to hull

    option -wrap -default 0 -validatemethod isa
    option -separator -default {} \
	-configuremethod C-separator -validatemethod isa
    # -pad provides general padding around the status bar
    # -ipad provides padding around each status bar item
    # Padding can be a list of {padx pady}
    option -ipad -default 2 -configuremethod C-ipad -validatemethod isa
    option -pad  -default 0 -configuremethod C-pad -validatemethod isa

    variable ITEMS -array {}
    variable uid 0
    typevariable septypes {top left bottom right {}}

    constructor {args} {
	$hull configure -height 18

	install frame using ttk::frame $win.frame

	install separator using ttk::separator $win.separator

	grid $frame -row 1 -column 1 -sticky news
	grid columnconfigure $win 1 -weight 1

	# we should have a <Configure> binding to wrap long toolbars
	#bind $win <Configure> [mymethod resize [list $win] %w]

	$self configurelist $args
    }

    method isa {option value} {
	set cmd widget::isa
	switch -exact -- $option {
	    -separator {
		return [uplevel 1 [list $cmd list $septypes $option $value]]
	    }
	    -wrap {
		return [uplevel 1 [list $cmd boolean $option $value]]
	    }
	    -ipad - -pad {
		return [uplevel 1 [list $cmd listofint 4 $option $value]]
	    }
	}
    }

    method C-ipad {option value} {
	set options($option) $value
	# returns pad values - each will be a list of 2 ints
	foreach {px py} [$self _padval $value] { break }
	foreach w [grid slaves $frame] {
	    if {[string match _sep* $w]} {
		grid configure $w -padx $px -pady 0
	    } else {
		grid configure $w -padx $px -pady $py
	    }
	}
    }

    method C-pad {option value} {
	set options($option) $value
	# we can pass this directly to the frame
	$frame configure -padding $value
    }

    method C-separator {option value} {
	set options($option) $value
	switch -exact -- $value {
	    top {
		$separator configure -orient horizontal
		grid $separator -row 0 -column 1 -sticky ew
	    }
	    left {
		$separator configure -orient vertical
		grid $separator -row 1 -column 0 -sticky ns
	    }
	    bottom {
		$separator configure -orient horizontal
		grid $separator -row 2 -column 1 -sticky ew
	    }
	    right {
		$separator configure -orient vertical
		grid $separator -row 1 -column 2 -sticky ns
	    }
	    {} {
		grid remove $separator
	    }
	}
    }

    # Use this or 'add' - but not both
    method getframe {} { return $win.frame }

    method add {what args} {
	if {[winfo exists $what]} {
	    set w $what
	    set symbol $w
	    set ours 0
	} else {
	    set w $frame._$what[incr uid]
	    set symbol [lindex $args 0]
	    set args [lrange $args 1 end]
	    if {![llength $args] || $symbol eq "%AUTO%"} {
		# Autogenerate symbol name
		set symbol _$what$uid
	    }
	    if {[info exists ITEMS($symbol)]} {
		return -code error "toolbar item '$symbol' already exists"
	    }
	    if {$what eq "label" || $what eq "button"
		|| $what eq "checkbutton" || $what eq "radiobutton"} {
		set w [ttk::$what $w -style Toolbutton -takefocus 0]
	    } elseif {$what eq "separator"} {
		set w [ttk::separator $w -orient vertical]
	    } elseif {$what eq "space"} {
		set w [ttk::frame $w]
	    } else {
		return -code error "unknown toolbar item type '$what'"
	    }
	    set ours 1
	}
	set opts(-weight)	[string equal $what "space"]
	set opts(-separator)	0
	set opts(-sticky)	news
	set opts(-pad)		$options(-ipad)
	if {$what eq "separator"} {
	    # separators shoudl not have pady by default
	    lappend opts(-pad) 0
	}
	set cmdargs [list]
	set len [llength $args]
	for {set i 0} {$i < $len} {incr i} {
	    set key [lindex $args $i]
	    set val [lindex $args [incr i]]
	    if {$key eq "--"} {
		eval [list lappend cmdargs] [lrange $args $i end]
		break
	    }
	    if {[info exists opts($key)]} {
		set opts($key) $val
	    } else {
		# no error - pass to command
		lappend cmdargs $key $val
	    }
	}
	if {[catch {eval [linsert $cmdargs 0 $w configure]} err]} {
	    # we only want to destroy widgets we created
	    if {$ours} { destroy $w }
	    return -code error $err
	}
	set ITEMS($symbol) $w
	$self isa -pad $opts(-pad)
	# returns pad values - each will be a list of 2 ints
	foreach {px py} [$self _padval $opts(-pad)] { break }

	# get cols,rows extent
	foreach {cols rows} [grid size $frame] break
	# Add separator if requested, and we aren't the first element
	if {$opts(-separator) && $cols != 0} {
	    set sep [ttk::separator $frame._sep[winfo name $w] \
			 -orient vertical]
	    # No pady for separators, and adjust padx for separator space
	    set sx [lindex $px 0]
	    if {$sx < 2} { set sx 2 }
	    lset px 0 0
	    grid $sep -row 0 -column $cols -sticky ns -padx $sx -pady 0
	    incr cols
	}

	grid $w -in $frame -row 0 -column $cols -sticky $opts(-sticky) \
	    -pady $py -padx $px
	grid columnconfigure $frame $cols -weight $opts(-weight)

	return $symbol
    }

    method remove {args} {
	set destroy [string equal [lindex $args 0] "-destroy"]
	if {$destroy} {
	    set args [lrange $args 1 end]
	}
	foreach sym $args {
	    set w $ITEMS($sym)
	    # separator is always previous item
	    set sep $frame._sep[winfo name $w]
	    if {[winfo exists $sep]} {
		# destroy separator for remove or destroy case
		destroy $sep
	    }
	    if {$destroy} {
		destroy $w
	    } else {
		grid forget $w
	    }
	    unset ITEMS($sym)
	}
    }

    method delete {args} {
	eval [linsert $args 0 $self remove -destroy]
    }

    method itemconfigure {symbol args} {
	if {$symbol eq "all"} {
	    # configure all, return # that failed the configure (0 == OK)
	    set code 0
	    foreach sym [array names ITEMS -glob $symbol] {
		incr code [catch { eval [linsert $args 0 \
					     $ITEMS($sym) configure] }]
	    }
	    return $code
	} elseif {[info exists ITEMS($symbol)]} {
	    # configure exact item
	    return [eval [linsert $args 0 $ITEMS($symbol) configure]]
	} else {
	    return -code error "unknown toolbar item '$symbol'"
	}
    }

    method itemcget {symbol option} {
	if {![info exists ITEMS($symbol)]} {
	    return -code error "unknown toolbar item '$symbol'"
	}
	return [$ITEMS($symbol) cget $option]
    }

    method itemidentify {symbol} {
	if {![info exists ITEMS($symbol)]} {
	    return -code error "unknown toolbar item '$symbol'"
	}
	return $ITEMS($symbol)
    }

    method items {{ptn *}} {
	if {$ptn ne "*"} {
	    return [array names ITEMS $ptn]
	}
	return [array names ITEMS]
    }

    method _padval {val} {
	set len [llength $val]
	if {$len == 0} {
	    return [list 0 0 0 0]
	} elseif {$len == 1} {
	    return [list [list $val $val] [list $val $val]]
	} elseif {$len == 2} {
	    set x [lindex $val 0] ; set y [lindex $val 1]
	    return [list [list $x $x] [list $y $y]]
	} elseif {$len == 3} {
	    return [list [list [lindex $val 0] [lindex $val 2]] \
			[list [lindex $val 1] [lindex $val 1]]]
	} else {
	    return $val
	}
    }

    method resize {w width} {
	if {$w ne $win} { return }
	if {$width < [winfo reqwidth $win]} {
	    # Take the last column item and move it down
	}
    }

}

package provide widget::toolbar 1.1

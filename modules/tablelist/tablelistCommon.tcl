#==============================================================================
# Main Tablelist and Tablelist_tile package module.
#
# Copyright (c) 2000-2024  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

namespace eval ::tablelist {
    #
    # Public variables:
    #
    variable version	7.2
    variable library	[file dirname [file normalize [info script]]]

    #
    # Creates a new tablelist widget:
    #
    namespace export	tablelist

    #
    # Sort the items of a tablelist widget by one or more of its columns:
    #
    namespace export	sortByColumn addToSortColumns

    #
    # Helper procedures used in binding scripts:
    #
    namespace export	convEventFields getTablelistPath getTablelistColumn \
			delaySashPosUpdates

    #
    # Register various widgets for interactive cell editing:
    #
    namespace export	addBWidgetEntry addBWidgetSpinBox addBWidgetComboBox
    namespace export    addIncrEntryfield addIncrDateTimeWidget \
			addIncrSpinner addIncrSpinint addIncrCombobox
    namespace export	addCtext addOakleyCombobox
    namespace export	addDateMentry addTimeMentry addDateTimeMentry \
			addFixedPointMentry addIPAddrMentry addIPv6AddrMentry
}

package provide tablelist::common $::tablelist::version

#
# The following procedure, invoked in "tablelist.tcl" and
# "tablelist_tile.tcl", sets the variable ::tablelist::usingTile
# to the given value and sets a trace on this variable.
#
proc ::tablelist::useTile {bool} {
    variable usingTile $bool
    trace add variable usingTile {write unset} \
	[list ::tablelist::restoreUsingTile $bool]
}

#
# The following trace procedure is executed whenever the variable
# ::tablelist::usingTile is written or unset.  It restores the
# variable to its original value, given by the first argument.
#
proc ::tablelist::restoreUsingTile {origVal varName index op} {
    variable usingTile $origVal
    switch $op {
	write {
	    return -code error "it is not supported to use both Tablelist and\
				Tablelist_tile in the same application"
	}
	unset {
	    trace add variable usingTile {write unset} \
		[list ::tablelist::restoreUsingTile $origVal]
	}
    }
}

proc ::tablelist::createTkAliases {} {
    foreach cmd {frame label} {
	if {[llength [info commands ::tk::$cmd]] == 0} {
	    interp alias {} ::tk::$cmd {} ::$cmd
	}
    }
}
::tablelist::createTkAliases

#
# Everything else needed is lazily loaded on demand, via the dispatcher
# set up in the subdirectory "scripts" (see the file "tclIndex").
#
lappend auto_path [file join $::tablelist::library scripts]

#
# Load the packages mwutil, scaleutil, and scaleutilmisc from the directory
# "scripts/utils".  Take into account that mwutil is also included in
# Mentry and Scrollutil, and scaleutil is also included in Scrollutil.
#
proc ::tablelist::loadUtils {} {
    if {[catch {package present mwutil} version] == 0 &&
	[package vcompare $version 2.22] < 0} {
	package forget mwutil
    }
    package require mwutil 2.22-

    if {[catch {package present scaleutil} version] == 0 &&
	[package vcompare $version 1.12] < 0} {
	package forget scaleutil
    }
    package require scaleutil 1.12-

    package require scaleutilmisc 1.6-
}
::tablelist::loadUtils

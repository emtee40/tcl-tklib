set rcsId {$Id: boxlabel.tcl,v 1.33 1998/03/28 20:34:38 jfontain Exp $}

class pieBoxLabeler {

    proc pieBoxLabeler {this canvas args} pieLabeler {$canvas $args} switched {$args} {
        switched::complete $this
    }

    proc ~pieBoxLabeler {this} {
        catch {::delete $pieBoxLabeler::($this,array)}                                        ;# array may not have been created yet
    }

    proc options {this} {                                      ;# font and justify options are used when creating a new canvas label
        # justify option is used for both the labels array and the labels
        return [list\
            [list -font $pieLabeler::(default,font) $pieLabeler::(default,font)]\
            [list -justify left left]\
            [list -offset 5 5]\
            [list -xoffset 0 0]\
        ]
    }

    foreach option {-font -justify -offset -xoffset} {                                                 ;# no dynamic options allowed
        proc set$option {this value} "
            if {\$switched::(\$this,complete)} {
                error {option $option cannot be set dynamically}
            }
        "
    }

    proc create {this slice args} {                                    ;# variable arguments are for the created canvas label object
        if {![info exists pieBoxLabeler::($this,array)]} {                                                  ;# create a labels array
            set box [$pieLabeler::($this,canvas) bbox pie($pieLabeler::($this,pie))]                     ;# position array below pie
            set pieBoxLabeler::($this,array) [new canvasLabelsArray\
                $pieLabeler::($this,canvas) [lindex $box 0] [expr {[lindex $box 3]+$switched::($this,-offset)}]\
                [expr {[lindex $box 2]-[lindex $box 0]}] -xoffset $switched::($this,-xoffset)\
            ]
        }
        set label [eval new canvasLabel $pieLabeler::($this,canvas) 0 0\
            $args [list -justify $switched::($this,-justify) -font $switched::($this,-font)]\
        ]
        canvasLabelsArray::manage $pieBoxLabeler::($this,array) $label
        # refresh our tags
        $pieLabeler::($this,canvas) addtag pieLabeler($this) withtag canvasLabelsArray($pieBoxLabeler::($this,array))
        switched::configure $label -text [switched::cget $label -text]:                        ;# always append semi-column to label
        set pieBoxLabeler::($this,selected,$label) 0
        return $label
    }

    proc delete {this label} {
        canvasLabelsArray::delete $pieBoxLabeler::($this,array) $label
        unset pieBoxLabeler::($this,selected,$label)
    }

    proc update {this label value} {
        regsub {:.*$} [switched::cget $label -text] ": $value" text
        switched::configure $label -text $text
    }

    proc selectState {this label {selected {}}} {
        if {[string length $selected]==0} {                                                   ;# return current state if no argument
            return $pieBoxLabeler::($this,selected,$label)
        }
        if {$selected} {
            switched::configure $label -borderwidth 2
        } else {
            switched::configure $label -borderwidth 1
        }
        set pieBoxLabeler::($this,selected,$label) $selected
    }

}

#!/usr/bin/wish

proc select_trig {i} {
  global trig_selected
  if {($trig_selected == $i)} {
    set trig_selected none
    .trig.mcanv itemconfig trigsq$i -width 1
  } else {
    .trig.mcanv itemconfig trigsq$trig_selected -width 1
    set trig_selected $i
    .trig.mcanv itemconfig trigsq$i -width 3
  }
}

proc select_toftrig {i} {
  global trig_selected tofbar_trig_bit trig_color
  set ind [expr $i + 1]
  if {($trig_selected == "none")} {
    set tofbar_trig_bit($i) "none"
    .trig.mcanv itemconfig tofbar$i -fill "#c0c0c0"
  } else {
    set tofbar_trig_bit($i) $trig_selected
    .trig.mcanv itemconfig tofbar$i -fill [lindex $trig_color $tofbar_trig_bit($i)]
  }
  update_trig_word_text
  .trig.labels.lbl2 configure -text {}
  .trig.labels.lbl3 configure -text {}
  .trig.labels.lbl4 configure -text {}
}

proc update_trig_word_text {} {
  global tofbar_trig_bit
  for {set i 0} {($i<=15)} {incr i} {
    set group_scheme($i) 0
  }
  for {set i 1} {($i<=50)} {incr i} {
    if {($tofbar_trig_bit($i) == "none")} {
      .trig.mcanv itemconfig trig_word_text -text "Trigger groups:"
      .trig.labels.docalc configure -state disabled
      return
    } else {
      set ind $tofbar_trig_bit($i)
      set group_scheme($ind) [expr $group_scheme($ind) + 1]
    }
  }
  set text ""
  for {set i 0} {($i<=15)} {incr i} {
    set text "${text}$group_scheme($i) "
  }
  .trig.mcanv itemconfig trig_word_text -text "Trigger groups: $text"
  .trig.labels.docalc configure -state active
}

proc grace_exit {} {
  exec -- kill -2 [pid]
}

proc calc_acc {} {
  global ea eb tofbar_trig_bit global_acc global_rate
  .trig config -cursor watch
  update
  set nt 0
  set nta 0
  for {set ievent 0} {($ievent < $ea(0))} {incr ievent} {
    for {set i 1} {($i <= 2)} {incr i} {
      for {set k 0} {($k < 16)} {incr k} {
        set word($i,$k) 0
      }
      unset k
      set nwa($i) 0
      for {set j 1} {($j <= 50)} {incr j} {
        if {($ea($ievent,$i,$j) == 1)} {
          set k $tofbar_trig_bit($j)
          set word($i,$k) 1
          set nwa($i) [expr $nwa($i) + 1]
        }
      }
      set nw($i) 0
      for {set k 0} {($k < 16)} {incr k} {
        if {($word($i,$k)==1)} {set nw($i) [expr $nw($i) + 1]}
      }
    }
    if {($nw(1)>1) && ($nw(2)>1)} {incr nt}
    if {($nwa(1)>1) && ($nwa(2)>1)} {incr nta}
  }
  set ntrs  [expr double($nt)  / double($ea(0))]
  set global_acc  $ntrs

  set ntrsa [expr double($nta) / double($ea(0))]
  set eff   [format %.5f [expr double($nt)  / double($ea(0))]]
  set effa  [format %.5f [expr double($nta) / double($ea(0))]]
  set relacc [format %.4f [expr double($nt)  / double($nta)]]
#  .trig.labels.lbl2 configure -text "$eff / $effa"
  .trig.labels.lbl2 configure -text $relacc


  update
  unset nw nwa word
  set nt 0
  set nta 0
  for {set ievent 0} {($ievent < $eb(0))} {incr ievent} {
    for {set i 1} {($i <= 2)} {incr i} {
      for {set k 0} {($k < 16)} {incr k} {
        set word($i,$k) 0
      }
      unset k
      set nwa($i) 0
      for {set j 1} {($j <= 50)} {incr j} {
        if {($eb($ievent,$i,$j) == 1)} {
          set k $tofbar_trig_bit($j)
          set word($i,$k) 1
          set nwa($i) [expr $nwa($i) + 1]
        }
      }
      set nw($i) 0
      for {set k 0} {($k < 16)} {incr k} {
        if {($word($i,$k)==1)} {set nw($i) [expr $nw($i) + 1]}
      }
    }
    if {($nw(1)>1) && ($nw(2)>1)} {incr nt}
    if {($nwa(1)>1) && ($nwa(2)>1)} {incr nta}
  }

  set eff [format %.5f [expr double($nt) / double($eb(0))]]
  set global_rate [expr double($nt) / double($eb(0))]

  set effa [format %.5f [expr double($nta) / double($eb(0))]]
  .trig.labels.lbl3 configure -text "$eff / $effa"

  set effr [format %.4f  [expr $ntrs  / ( double($nt)  / double($eb(0)) )]]
  set effra [format %.5f [expr $ntrsa / ( double($nta) / double($eb(0)) )]]
  .trig.labels.lbl4 configure -text "$effr"

  .trig config -cursor {}
  update
}

set trig_color "#c0ffff #70ffff #ffc0c0 #ff7070 #ffc0ff #ff70ff #c0ffc0 #70ff70 \
                #ffffc0 #ffff70 #c0c0ff #7070ff #ffb050 #b0ff50 #b050ff #f7f7f7"
set trig_selected none

wm withdraw .
catch {destroy .trig}

puts "reading MC data"
set fid [open "|gunzip -c mc_eff.dat.gz"]
set ievent 0
while {([eof $fid] == 0)} {
  set line [gets $fid]
  set ll [string length $line]
  if {($ll == 100)} {
    set k 0
    for {set i 1} {($i <= 2)} {incr i} {
      for {set j 1} {($j <= 50)} {incr j} {
        set ea($ievent,$i,$j) [string index $line $k]
        incr k
      }
    }
    incr ievent
  }
  set ea(0) $ievent
}
catch {close $fid}
puts "done reading MC data, $ievent events"

puts "reading beam data"
set fid [open "|gunzip -c tof_bckgr.dat.gz"]
set ievent 0
while {([eof $fid] == 0)} {
  set line [gets $fid]
  set ll [string length $line]
  if {($ll == 100)} {
    set k 0
    for {set i 1} {($i <= 2)} {incr i} {
      for {set j 1} {($j <= 50)} {incr j} {
        set eb($ievent,$i,$j) [string index $line $k]
        incr k
      }
    }
    incr ievent
  }
  set eb(0) $ievent
}
catch {close $fid}
puts "done reading 20nA data, $ievent events"

toplevel .trig

bind .trig <Destroy> {grace_exit}

wm title .trig "TOF TRIGGER GROUPS"
wm iconname  .trig "TOF"
wm resizable .trig 1 1
set init_sizeX 900
set init_sizeY 600
wm geometry  .trig ${init_sizeX}x${init_sizeY}+80+10
wm minsize   .trig 300 200
wm maxsize   .trig 1200 1000

canvas .trig.mcanv -relief ridge -borderwidth 5 -closeenough 0

set opt1 " -height 1 -relief sunken -bd 2 -anchor w -width 6"
set opt2 " -height 1 -relief flat -anchor e -width 16"
set opt2a " -height 1 -relief flat -anchor e -width 12"
set opt2b " -height 1 -relief flat -anchor e -width 24"
set opt3 " -height 1 -relief flat -anchor e -width 16"

frame .trig.labels -relief flat -bd 10

button .trig.labels.docalc -text Calculate -command {update_trig_word_text; calc_acc} \
    -relief raised -bd 1 -width 6 -state disabled
button .trig.labels.exit -text Exit -command {grace_exit} \
    -relief raised -bd 1 -width 6  -activebackground "#c00000" -activeforeground white
eval label .trig.labels.lbl1  $opt2b  -text {{Relative acceptance:}}
eval label .trig.labels.lbl1a $opt2a  -text {{Background:}}
eval label .trig.labels.lbl1b $opt2b  -text {{Acceptance / background}}
eval label .trig.labels.lbl2 $opt1
eval label .trig.labels.lbl3 $opt1
eval label .trig.labels.lbl4 $opt1

pack .trig.labels  -side top -expand no -fill both -anchor w
pack .trig.labels.docalc .trig.labels.lbl1 .trig.labels.lbl2 \
                         .trig.labels.lbl1b .trig.labels.lbl4 -side left -expand no -fill none -in .trig.labels
pack .trig.labels.exit -side right -expand no -fill none -in .trig.labels

pack .trig.mcanv -side top -expand yes -fill both -in .trig

bind .trig <Control-p> {
  .trig.mcanv postscript -file m.eps -rotate 1 -width 800 -height 600
}

set x2 120
set scale 2.5
set offset 2
for {set i 1} {($i<=50)} {incr i} {
  if {($i <= 17) || ($i > 50-17)} {
    set width 6
  } elseif {($i == 20) || ($i == 21) || ($i == 30) || ($i == 31)} {
    set width 3
  } else {
    set width 4.5
  }
  set width $width*$scale

  if {($i>=22) && ($i<=29)} {
    if [expr $i%2] {
      set y1 280
      set y2 450
    } else {
      set x1 [expr $x2 + $offset]
      set x2 [expr $x1 + $width]
      set y1  50
      set y2 220
    }
  } else {
    set x1 [expr $x2 + $offset]
    set x2 [expr $x1 + $width]
    set y1  50
    set y2 450
  }

  .trig.mcanv create rect $x1 $y1 $x2 $y2 -fill "#c0c0c0" -tags tofbar$i
  set tofbar_trig_bit($i) "none"
  .trig.mcanv bind tofbar$i <1> "select_toftrig $i"
}
unset x1 x2 y1 y2 i

set y2 40
for {set i 0} {($i<=15)} {incr i} {
  set x1 20
  set x2 30
  set y1 [expr $y2 + 15]
  set y2 [expr $y1 + 10]
  .trig.mcanv create rect $x1 $y1 $x2 $y2 -fill [lindex $trig_color $i] -tags trigsq$i
  .trig.mcanv create text [expr $x1 + 25] [expr $y1 + 6] -text "$i" -tags scale
  .trig.mcanv bind trigsq$i <1> "select_trig $i"
}
unset x1 x2 y1 y2 i

.trig.mcanv create text 350 480 -text "Trigger groups: " -width 350 -tags trig_word_text

bind all <Alt-Any-Key> {break}  ;# to avoid global bindings
update

set default_pattern "0 0 0 0 0 0 1 1 1 1 1 1 2 2 2 2 2 3 4 5 6 7 7 7 7 8 8 8 8 9 10 11 12 13 13 13 13 13 \
                     14 14 14 14 14 14 15 15 15 15 15 15"

for {set i 1} {($i<=50)} {incr i} {
  set tofbar_trig_bit($i) [lindex $default_pattern [expr $i-1]]
  .trig.mcanv itemconfig tofbar$i -fill [lindex $trig_color $tofbar_trig_bit($i)]
}
.trig.labels.docalc configure -state active

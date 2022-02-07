#!/bin/bash
#
# addfonts.sh
# Converts True Type or Open Type Fonts to Postscript Type1 Fonts and populates
# the Ghostscript Fontmap file and the Basser Lout FontDef databases for local
# users.
#
# Depends on non-standard commands: ttfpt1 (compiled against Freetype)
#
#
# Copyright 2014 Martin Michel
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may not
#   use this file except in compliance with the License.  You may obtain a copy
#   of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
#   License for the specific language governing permissions and limitations
#   under the License.
    
shfile=$(sed 's/^.*\///' <<< "$0") 
logfile=$(sed -e 's/\.sh/\.log/; s/^.*\///' <<< "$0")
#echo $0 $shfile $logfile

usage="Usage: ./$shfile 
No arguments applicable. This script scans for new True Type or Open Type Font
files, converts them to Postscript Type1 Fonts and updates the Fontmap
(Ghostscript) and @FontDef (Lout) databases. The script and all associated input
and output files must be in the local user ghostscript font path."

echo "*****************************************************************"\
   >>"$logfile"
echo "LOG ENTRY from '$shfile'">>"$logfile" 
echo -e "Run by $USER on $HOSTNAME at $(date) \n ">>"$logfile" 

if [ $# -gt 0 ] ; then 
    echo -e "TERMINATION: Wrong number of arguments. \n" |tee -a "$logfile" 
    echo -e "$usage\n" 
    exit 1 
fi

if [[ "$GS_FONTPATH" != "$(pwd)" ]] ; then 
    echo -e "TERMINATION: Wrong working directory or GS_FONTPATH not set.\n" |tee -a "$logfile" 
    echo -e "Current directory: $(pwd)" |tee -a "$logfile"
    echo -e "GS_FONTPATH: $GS_FONTPATH" |tee -a "$logfile"
    echo -e "$usage\n" 
    exit 2 
fi

[ ! -f Fontmap ] && echo -e "INFO: Ghostscripts local 'Fontmap' file missing, will
be created.\n" |tee -a "$logfile"  && touch Fontmap

ls ./*.[oOtT][tT][fF] 2>/dev/null 1>&2 
if [ $? -ne 0 ] ; then 
    echo -e "TERMINATION: No True or Open Type Font files (.ttf,.otf) in directory." |tee -a "$logfile" 
    echo -e "$usage\n" 
    exit 3 
fi

availableTTF=( $(find . -name "./*.[oOtT][tT][fF]" | sed 's/\.otf\|\.ttf//i') )
installedPFB=( $(grep -e '^/' Fontmap | sed 's/^.*(\|\.pfb.*$//g') )

typeset -i counter 
typeset -i numTTF 
typeset -i numInstalled
typeset -i numPFB
numTTF=${#availableTTF[*]} 
numInstalled=${#installedPFB[*]}
counter=$numInstalled
numPT1=$(find . -name  "./*.[aApP][fF][bBmM]" 2>/dev/null | wc -l ) 

let z=numPT1/2
let m=numPT1%2

if (( numInstalled < z && m == 0 )) ; then
    echo -e "WARNING: There are unregistered PS Type1 font files.\n" |tee -a "$logfile"
elif (( numInstalled > z || m > 0 )) ; then
    echo -e "TERMINATION: There are missing PS Type1 font files. It is recommend to
syncronize all files and databases in this directory (delete Fontmap and rerun
$0)\n" |tee -a "$logfile"
    exit 4
fi

echo -e "STATUS: There are $numInstalled installed Postscript Type1 Fonts out of $numTTF
available True Type or Open Type Fonts for user $USER. \n" >>"$logfile"

if (( numTTF != numInstalled ))
then
    for ii in "${availableTTF[@]}"; do
        for jj in "${installedPFB[@]}"; do
            if [[ "$ii" != "$jj" ]]; then
                counter=$counter-1
            fi
        done
        if (( counter ==  0 )) ; then
            queueFonts=("${queueFonts[@]}" "$ii")
        fi
       counter=$numInstalled
    done
else
    echo "INFO: Font database is up-to-date if you have not fiddled with the
contents of this directory or the local Fontmap file manually after the
last run of this script. Consult the log file for history.
    
Nothing to do. No new fonts installed." |tee -a "$logfile"
    exit 0
fi

for ff in "${queueFonts[@]}"; do
    echo "-----------------------------------------------------------------"\
       >>"$logfile"
    echo "START OF TTF2PT1 LOG ENTRY FOR '$ff'" >>"$logfile"
    date >>"$logfile"
    echo "-----------------------------------------------------------------"\
       >>"$logfile"

    ttf2pt1 -b "$ff".[oOtT][tT][fF]  >>"$logfile" 2>&1

    fontNames=("${fontNames[@]}" "$(grep FontName "$ff".afm | cut -d' ' -f2-)")
    familyNames=("${familyNames[@]}" \
        "$(grep FamilyName "$ff".afm | cut -d' ' -f2- | sed 's/ /_/g')")
    faceNames=("${faceNames[@]}" \
        "$(grep Weight "$ff".afm | cut -d' ' -f2- | \
        sed -e' s/^./\U&/g; s/ *//g; s/Regular/Base/i; s/Italic/Slope/i ')")
    tagNames=("${tagNames[@]}" "${familyNames[@]:(-1)}-${faceNames[@]:(-1)}")

    echo "/${fontNames[*]:(-1)}						 ($ff.pfb);" >>Fontmap
    
    if [[ -z $(cat myfontdefs.ld | sed -n '/'"$ff"'.afm/p') ]] ; then
        cat >>myfontdefs.ld<<LOUT_ENTRY 
{ @FontDef
      @Tag { ${tagNames[@]:(-1)} }
      @Family { ${familyNames[@]:(-1)} }
      @Face { ${faceNames[@]:(-1)} }
      @Name { ${fontNames[@]:(-1)} }
      @Metrics { $ff.afm } 
      @Mapping { LtLatin1.LCM }
}

LOUT_ENTRY
    fi
    
    # Correct for whitespace error in afm files
    sed -i 's/.null/space/' "$ff".afm

    echo "*****************************************************************"\
        >>"$logfile"
    echo -e "Font: ${fontNames[*]:(-1)}; Tag: ${tagNames[*]:(-1)} (has been \
installed.)" |tee -a "$logfile"
done

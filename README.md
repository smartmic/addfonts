addfonts
========

This single Bash script converts your TTF or OTF font type files to Postscript
Type1 files, updates the Fontmap file and also populates the user font database
for the Lout typesetting system.

## Motivation

[Basser Lout](http://savannah.nongnu.org/projects/lout) is an excellent
typesetting system, unfortunately living a shadowy existence when comparing to
LaTex. I gained experience with LaTex and Groff, all have their strengths and
weaknesses. If I should recommend a system to a typesetting newbie, I clearly
would recommend Lout. It is very feature-rich, easy to learn and leaves a small
footprint on your system.  To typeset beautiful documents, one does not want to
stick to the fonts supplied by Lout but needs easy and hassle-free access to all
installed fonts. After all, typography is important for any serious author or
design oriented individual.

The process to embed custom fonts into documents set by Tex, Troff or Lout is
basically the same, you have to provide Postscript fonts.

## Realization

This script converts the fonts of your choice to those PS Type1 fonts, updates
Ghostscripts Fontmap file and adds an entry for each font to a personal font
database for Lout (default name: myfontdefs.ld). The first part may be helpful
for LaTex and Groff users as well.

The conversion is done by the external program
[ttf2pt1](http://ttf2pt1.sourceforge.net/), it is up you to switch
to other tools, e.g. Tex distribution supply some tools for this as well. My
goal was to achieve an installation process without any manual interference.
Although ttf2pt1 is quite an old tool and did need some patches on my Mac OS X
and Linux system, it produces very nice PS fonts. It relies on the Freetype2
library for conversion of TTF and OTF fonts. You can also stick to the built-in
TTF converter, however, it will not convert OTF fonts.

## Usage

You may have to adopt the script to your specific needs. My setup is that I have
all fonts in a directory (~/.fonts). The script (or a link to it) also residues
there as well as all related PS font files (.afm, .pfb, Fontmap).

To install new fonts for usage with Lout, just extract the .ttf or .oft files in
this directory and run

    ./addfonts.sh

The script is quite communicative and also logs its output (and the output of
ttf2pf1) to addfonts.log. 

### Excursus 1: How to install ttf2pf1

Choose a suitable installation directory and download the sources:

    wget http://prdownloads.sourceforge.net/ttf2pt1/ttf2pt1-3.4.4.tgz

Also get the header files for the Freetype 2 library (if not already installed),
use your package manager. Here is an example for Debian systems: 

    sudo apt-get install libfreetype6-dev

Extract the tarball:

    tar xvzf ttf2pt1-3.4.4.tgz

Move the patch files which are part of the repository to the current
directory and apply *ft.patch* at first:

    mv ~/my_addfonts_path/*.patch .
    patch ./ttf2pt1-3.4.4/ft.c < ft.patch

Now adopt the Makefile in ttf2pt1-3.4.4 according your needs. You may find my
Makefile useful, it will give you a good starting point (the original Makefile
had a typo in the *sed* expressions):

    patch ./ttf2pt1-3.4.4/Makefile < Makefile.patch

Run make and make install to compile and install ttf2pt1 on your system:

    cd ttf2pf1
    make
    sudo make install

### Excursus 2: How to use different fonts in Lout

It is quite straightforward to use a TTF/OTF font in your Lout document. Having
run addfonts.sh, the user font database for Lout is available in the same
font directory (myfontdefs.ld). Lout by itself needs only the .afm files, creating PS and PDF
files with Ghostscript requires also the .pfb (binary) or .pfa (ascii) files.
Check in myfontdefs.ld for the entry of the font(s) you want to use. The
addfonts.log will also tell you which fonts have been installed. In your Lout
document add the database without full path or suffix:

    @Database @FontDef{ myfontdefs }

Now use the new font in Lout wherever needed, here is an example of setting an
alternative font for a report type document "globally":

    @InitialFont { Minion_Pro Base 12p }

The user manual is very, very helpful and well written, consult it for all about
fonts. If you want to dive deeper, there is also an expert manual, you may give
it a try.
To be consistent with Louts naming, I mapped some commonly used font faces:  

  * Regular --> *Base*  
  * Italic --> *Slope*  

Just make sure that you use the correct font family and face name as written in
myfontdefs.ld.

Last but not least, do not forget to tell Lout that you have a customized
external font database when invoking:

    lout -D/path/to/directory/of/database -F/path/to/directory/of/fontmetrics

Remember, in my setup, I have the font metric files (.afm) and database
(myfontdefs.ld) in the same path. That is also a registered Ghostscript font path
containing the Fontmap file and the .pfb files. Check that the variable $GS\_FONTPATH
contains this path. Currently addfonts.sh is glued to this environment variable.
A future release shall omit this restriction and make any search path accessible
as defined by **-I, GS\_LIB** and **GS\_LIB\_DEFAULT** or with the **-sFONTPATH=**
switch. Alternatively, you can modify addfonts.sh by yourself.  

####
**Now, good luck and enjoy beautiful documents with any fonts you like!**

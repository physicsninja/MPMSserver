This is a work in progress. The goal is to modernize the QD MPMS software interface so that new users don't have to learn Delphi and can write in more modern programming languages.

### Why does this exist

Quantum Design is a pretty cool company and back in the early 2000's they deigned to allow users to use their MPMS as a PPMS by including libraries for Delphi so that one could interface with other devices and also control the MPMS. This was known as External Device Control (EDC). Delphi is in some sense a precursor to Python and this was a good choice at the time for it's relative readability and straightforward syntax.

However, technology has advanced, but QD no longer supports their MPMS versions 1 and 2 with new software updates. In particular, modern PPMS's have an instrument server that one can send commands to to control and read from the PPMS. This is an attempt to remedy this situation. I am not affiliated with QD. 

### What does this repository do

Included are (currently untested) delphi .dpr file that should (probably) compile that implements a client that constantly polls another python server (asynioserver.py) that serves as a broker. Why not have the Delphi EDC code be the server? The way that the EDC is invoked by the MPMS means that I couldn't create (or at least not simply) a persistent server and that didn't break the structure the MPMS expects. Thus this was the compromise. User code should connect to the Python server and issue it commands and read from it. 

In order for the EDC to compile, you will need Indy 10 and Delphi 7. Maybe this will work with other versions but I didn't test them. Delphi 7 can be found for free at the winworldpc.com archive and Indy 10 from https://github.com/IndySockets/Indy . Installation instructions for Indy can be found http://ww2.indyproject.org/Sockets/Download/DevSnapshot.EN.aspx . I include a zipped version of Indy that I used to get everything working and a copy of the installation instructions in this repository for posterity in case the Indy project disappears. While I advise you not to trust my zipped archive on principle and offer no warranty for its validity, I will state that I provided it in good faith. Delphi 7 installs on Windows 10 just fine as far as I can tell (the MPMS MultiVu that originally came on floppies also does too!) 

The basic structure of the installation process for Indy10 is to first uninstall Indy7 from Delphi7 by removing it from the components list by using the Components->Install Packages tool in Delphi7 then removing all indy components from Delphi7 Lib, Source, and Bin (one can search for Indy and Id and remove them. Caution: there are a few IDL files which are not associated with Indy. Indy components are prefixed by Id.) Then run the Fulld_7.bat file in the Lib subdirectory of the unzipped Indy10 archive then to copy the resulting D7 folder into the Source folder of the Delphi installation. Then, use the Component->Install Packages->Add Packages tools to select all of the files in the D7 folder in the resulting dialogue box. Delphi may complain about missing components or being unable to find some packages, just silence those warnings, they do not affect the compilation of the file.

### Why do we need Indy10, installing it tedious and I just want to get on with my life

Believe me, if I could have written with stock Indy7 in the Delphi7 from winworldpc I would have. I tried to write TCP client that would do what I want and it was taking a really long time so I decided to just use the more modern version that has everything I need. It's worth the trade off. If you are a Delphi wizard, be my guest and submit a pull request.

### Why does the server reply yeet to everything

Because the world needs more whimsy, and it is a four character string which is the length that I chose for communication strings. 





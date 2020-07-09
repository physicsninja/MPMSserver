This is a work in progress. The goal is to modernize the QD MPMS software interface so that new users don't have to learn Delphi and can write in more modern programming languages.

### How to use this repository

Compile the MPMSserver Delphi library in this repository (you will likely need to upgrade to Indy 10 in your current Delphi installation and/or install the Delphi IDE). The DLL itself is not in this repository because one really shouldn't download DLL's from the internet without guarantee of provenance. If you absolutely cannot get the compilation to work, raise an issue and I will either try to help you or send you the DLL.

Run the asynioserver.py. 

Run the resulting DLL from the MPMSserver using the EDC option of the MultiVu sequence normally. The Init and Exec functions need no arguments. 

While in the Exec function, the EDC code will constantly poll the server for any new instructions and will return results to the server in response to commands (and I do mean constantly, there is no delay in the `repeat ... until` loop). Commands to send to the server from your favorite programming language (although if that language is Delphi why are you even reading this?) using TCP/IP are describe in [NEEDTOWRITE.txt]. You will either be sending a GPIB address + raw GPIB string or commands to the magnet/system itself. 

A demo notebook is forthcoming.

### Why does this exist

Quantum Design is a pretty cool company and back in the early 2000's they deigned to allow users to use their MPMS as a PPMS by including libraries for Delphi so that one could interface with other devices and also control the MPMS. This was known as External Device Control (EDC). Delphi is in some sense a precursor to Python and this was a good choice at the time for it's relative readability and straightforward syntax.

However, technology has advanced, but QD no longer supports their MPMS versions 1 and 2 with new software updates.  In particular, modern PPMS's have an instrument server that one can send commands to to control and read from the PPMS. Fortunately, the MultiVu software and the EDC extensions and a suitable version of Delphi all still install and run just fine under Windows 10 (in my case, at least, YMMV) so this is an attempt to remedy this situation. I am not affiliated with QD. 

### What does this repository do

This is a delphi .dpr file that should compile under Delphi7 with Indy10 that implements a client that constantly polls another python server (asynioserver.py) that serves as a broker. Why not have the Delphi EDC code be the server? The way that the EDC is invoked by the MPMS means that I couldn't create (or at least not simply) a persistent server and that didn't break the structure the MPMS expects. Thus this was the compromise. User code should connect to the Python server and issue requests to the MPMS through it. This is not an elegant solution and I almost feel dirty about doing it this way, but it works and it is fairly straightforward to debug.

In order for the code I wrote to compile, you will need Delphi, Indy 10, and the MPMS Delphi extensions. Delphi 7 can be found for free at the winworldpc.com archive and Indy 10 from https://github.com/IndySockets/Indy (Other versions of Delphi and Indy >7 may work but I didn't test them). Installation instructions for Indy can be found http://ww2.indyproject.org/Sockets/Download/DevSnapshot.EN.aspx . I include a zipped version of Indy that I used to get everything working, a copy of the installation instructions and some notes on installing in this repository for posterity in case the Indy project disappears. While I advise you not to trust my zipped archive on principle and offer no warranty for its validity, I will state that I provided it in good faith. Delphi 7 installs on Windows 10 just fine as far as I can tell (the MPMS MultiVu that originally came on floppies also does too!) 

### Why do we need Indy10, installing it tedious and I just want to get on with my life

Believe me, if I could have written with stock Indy7 in the Delphi7 from winworldpc I would have. I tried to write the TCP client that would do what I want and it was proving intractable so I decided to just use the more modern version that has everything I need. It's worth the trade off. If you are a Delphi wizard, be my guest and submit a pull request.

### Why does the server reply `yeet` to everything

Because the world needs more whimsy, and it is a four character string which is the length that I chose for communication strings. 





# Leek

Leek is a free command-line password manager, which makes it easily usable through a SSH terminal connection. It currently targets Linux, which is the OS I use, but you are welcomed to port it to yours if you want. 


## Should I really use a password manager?

Oh well, since I have written my own, I will say yes, but you'll probably want [more polished arguments](https://www.youtube.com/watch?v=7U-RbOKanYs).


## How does Leek store my passwords?

Your master password hash and its salt are stored using bcrypt. The master password itself is never stored. Then your password database is ciphered using AES-256.


## Build instructions

Leek is written in the D programmming language, so you'll need to install [a D compiler](http://dlang.org/download.html#dmd) on your system if you haven't yet. 

Then clone this repository, open a terminal, cd into the project root directory and type 

    dub build

to create a debug build or 

    dub build --build=release

to create a release build. Dub is the D equivalent of make and comes with the D compiler. It will take care of downloading and building the Leek dependencies before building Leek itself.


## Running unit tests

Since I am sure we are beween well educated people, you know the importance of writing and running unit tests. Simply type 

    dub test 

to create and run a unit test build of Leek. 


## Dependencies

For your information, the only third party library Leek depends on is the Botan crypto library.


## License 

Leek is written under the [GNU General Public License v3](https://github.com/opisano/leek/blob/master/LICENSE). 

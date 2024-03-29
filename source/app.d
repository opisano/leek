/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Copyright 2017 Olivier Pisano.
    This file is part of Leek.

    Leek is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Leek is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Leek.  If not, see <http://www.gnu.org/licenses/>.

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

import botan.all;

import leek.account;
import leek.fileformat;
import leek.interpreter;
import leek.io;
import leek.validate;

import std.ascii;
import std.algorithm;
import std.file;
import std.path;
import std.stdio;
import std.string;
import std.typecons;

void main(string[] args)
{
    try
    {
        LibraryInitializer init;
        init.initialize();

        auto io = createIO();
        io.display("Leek password manager\n");
        auto filename = databaseFilename();
        Tuple!(AccountManager, string) mgrPwd;

        if (!filename.exists)
        {
            io.display("No existing password database found.\n");
            mgrPwd = createDatabase(filename, io);
        }
        else
        {
            mgrPwd = openDatabase(filename, io);
        }

        io.display("\n");
        auto interpreter = Interpreter(mgrPwd[0], io, mgrPwd[1], filename);
        interpreter.mainLoop();
    }
    catch(Exception e)
    {
        writeln(e.msg);
    }
}

/**
 * Create the account database the first time leek is run.
 * 
 * Params:
 *     filename = The name of the file where to store the database.
 *     io       = An IO object to interact with the user.
 * 
 * Returns:
 *     The AccountManager, masterPassword tuple to the database newly created. 
 */
private auto createDatabase(string filename, IO io)
{
    io.display("Creating password database in %s\n".format(filename));
    filename.dirName.mkdirRecurse;
    auto masterPassword = chooseMasterPassword!validatePassword(io);
    auto factory = latestWriterFormat();
    auto writer = factory.createFileWriter(masterPassword);
    auto mgr = createAccountManager();
    writer.writeToFile(mgr, filename);
    return tuple(mgr, masterPassword);
}

/**
 * Opens the account database.
 *
 * Params:
 *     filename = The name of the file where to store the database.
 *     io       = An IO object to interact with the user.
 * 
 * Returns:
 *     The AccountManager, masterPassword tuple to the database opened. 
 */
private auto openDatabase(string filename, IO io)
{
    string masterPassword;
    auto factory = latestReaderFormat();

    while (true)
    {
        try
        {
            masterPassword = io.inputPassword("Please type master password: ");
            auto reader = factory.createFileReader(masterPassword);
            auto mgr = reader.readFromFile(filename);
            return tuple(mgr, masterPassword);
        }
        catch (WrongPasswordException)
        {
            io.display("Incorrect password. Try again...");
        }
    }
}

/**
 * Assists the user in typing its master password for the first time.
 *
 * Params:
 *     validate = an alias to a bool function(string, IO) that will check the 
 *                validity of a password.
 *     io       = A IO object to interact with the user. 
 * Returns:
 *     The master password chosen by the user. 
 */
private string chooseMasterPassword(alias validate)(IO io)
{
    io.display("Please choose a master password. \n"
               ~ "Your master password should be long (more than 12 chars) "
               ~ "and should contain uppercase and lowercase letters, digits, "
               ~ "and special characters.\n");

    auto password = "";
    auto password2 = "";
    auto valid = false;

    while (!valid || (password != password2))
    {
        password = io.inputPassword("\nEnter password: ");
        password2 = io.inputPassword("\nEnter password (confirmation): ");
        io.display("\n");
        valid = validate(password, io);

        if (password != password2)
        {
            io.display("Passwords do not match\n");
        }
    }

    return password;
}



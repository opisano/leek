/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

import botan.all;

import leek.account;
import leek.fileformat;
import leek.interpreter;
import leek.io;

import std.ascii;
import std.algorithm;
import std.file;
import std.path;
import std.stdio;
import std.string;

void main(string[] args)
{
    try
    {
        LibraryInitializer init;
        init.initialize();

        auto io = createIO();
        io.display("Leek password manager\n");
        auto filename = databaseFilename();
        AccountManager mgr;

        if (!filename.exists)
        {
            io.display("No existing password database found.\n");
            mgr = createDatabase(filename, io);
        }
        else
        {
            mgr = openDatabase(filename, io);
        }

        io.display("\n");
        auto interpreter = Interpreter(mgr, io);
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
 *     The AccountManager to the database newly created. 
 */
private AccountManager createDatabase(string filename, ref IO io)
{
    io.display("Creating password database in %s\n".format(filename));
    filename.dirName.mkdirRecurse;
    auto masterPassword = chooseMasterPassword!validatePassword(io);
    auto factory = latestWriterFormat();
    auto writer = factory.createFileWriter(masterPassword);
    auto mgr = createAccountManager();
    writer.writeToFile(mgr, filename);
    return mgr;
}

/**
 * Opens the account database.
 *
 * Params:
 *     filename = The name of the file where to store the database.
 *     io       = An IO object to interact with the user.
 * 
 * Returns:
 *     The AccountManager to the database opened. 
 */
private AccountManager openDatabase(string filename, ref IO io)
{
    string masterPassword;
    auto factory = latestReaderFormat();

    while (true)
    {
        try
        {
            masterPassword = io.input_password("Please type master password: ");
            auto reader = factory.createFileReader(masterPassword);
            auto mgr = reader.readFromFile(filename);
            return mgr;
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
private string chooseMasterPassword(alias validate)(ref IO io)
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
        password = io.input_password("\nEnter password: ");
        password2 = io.input_password("\nEnter password (confirmation): ");
        io.display("\n");
        valid = validate(password, io);

        if (password != password2)
        {
            io.display("Passwords do not match\n");
        }
    }

    return password;
}

/**
 * Checks that a password is reasonably valid.
 *
 * Params:
 *     password = the password to check.
 *     io       = A IO object to to interact with the user.
 *
 * Returns:
 *     true if the password is considered valid, false otherwise.
 */
private bool validatePassword(string password, ref IO io)
{
    // TODO consider user libcrack to check this. 

    enum MIN_PASSWORD_LENGTH = 12;
    bool valid = true;

    if (password.length < MIN_PASSWORD_LENGTH)
    {
        io.display("Password is too short\n");
        valid = false;
    }

    if (!password.canFind!(c => c.isUpper))
    {
        io.display("Password does not contain uppercase letters\n");
        valid = false;
    }

    if (!password.canFind!(c => c.isLower))
    {
        io.display("Password does not contain lowercase letters\n");
        valid = false;
    }

    if (!password.canFind!(c => c.isDigit))
    {
        io.display("Password does not contain digits\n");
        valid = false;
    }

    return valid;
}


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

module leek.interpreter;

import leek.account;
import leek.commands;
import leek.fileformat;
import leek.io;

import std.string;


/**
 * Runs a main loop where it interprets commands typed by the users and creates 
 * the corresponding Command objects.
 */
struct Interpreter
{
    this(AccountManager mgr, IO io, string masterPassword, string filename)
    {
        this.mgr = mgr;
        this.io = io;
        this.masterPassword = masterPassword;
        this.filename = filename;
    }

    void mainLoop()
    {
        while (true)
        {
            string line = io.input(">>> ");
            auto cmd = parseLine(line);
            bool modified = cmd.execute(mgr, io);
            
            if (modified)
            {
                auto factory = latestWriterFormat();
                auto writer = factory.createFileWriter(masterPassword);
                writer.writeToFile(mgr, filename);
            }
        }
    }

private:
    
    /**
     * Initialize the object.
     */
    void initialize()
    {
        io = createIO();
    }

    /**
     * Parse the line entered by the user, and returns the 
     * corresponding Command object.
     *
     * Params:
     *     line = The text entered by the user.
     *
     * Returns:
     *     a Command object corresponding to the line entered by the user.
     */
    Command parseLine(string line)
    {
        line = line.strip();
        auto elements = line.split();
        if (elements.length)
        {
            if (line == "h" || line == "help")
                return new HelpCommand;
            if (line == "q" || line == "quit")
                return new QuitCommand;
            if (elements[0] == "add" && elements.length > 1)
                return new AddAccountCommand(elements[1]);
            if (elements[0] == "get" && elements.length > 1)
                return new GetAccountCommand(elements[1]);
            if (elements[0] == "list")
                return new ListAccountsCommand;
            if (elements[0] == "dir")
            {
                if (elements.length == 1)
                    return new DirCommand();
                else
                    return new DirCommand(elements[1]);
            }
            if (elements[0] == "tag" && elements.length > 2)
                return new TagAccountCommand(elements[1], elements[2]);
        }

        return new UnknownCommand;
    }

    AccountManager mgr;
    IO io;
    string masterPassword;
    string filename;
}


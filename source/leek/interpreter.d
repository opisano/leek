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
                else if (elements.length == 2)
                    return new DirCommand(elements[1]);
            }
            if (elements[0] == "tag" && elements.length > 2)
                return new TagAccountCommand(elements[1], elements[2]);
            if (elements[0] == "untag" && elements.length > 2)
                return new UntagAccountCommand(elements[1], elements[2]);
            if (elements[0] == "del" && elements.length > 1)
                return new DelCategoryCommand(elements[1]);
            if (elements[0] == "remove" && elements.length > 1)
                return new RemoveAccountCommand(elements[1]);
            if (elements[0] == "change")
            {
                if (elements.length == 2)
                    return new ChangePasswordCommand(elements[1]);
                else if (elements.length == 3)
                    return new ChangePasswordCommand(elements[1], elements[2]);
            }

        }

        return new UnknownCommand;
    }

    AccountManager mgr;
    IO io;
    string masterPassword;
    string filename;
}

unittest
{
    auto inter = Interpreter(null, null, null, null);
    assert ((cast(HelpCommand)inter.parseLine("h")) !is null);
    assert ((cast(HelpCommand)inter.parseLine("help")) !is null);
    assert ((cast(QuitCommand)inter.parseLine("q")) !is null);
    assert ((cast(QuitCommand)inter.parseLine("q")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("add")) !is null);
    assert ((cast(AddAccountCommand)inter.parseLine("add ebay")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("get")) !is null);
    assert ((cast(GetAccountCommand)inter.parseLine("get ebay")) !is null);
    assert ((cast(ListAccountsCommand)inter.parseLine("list")) !is null);
    assert ((cast(DirCommand)inter.parseLine("dir")) !is null);
    assert ((cast(DirCommand)inter.parseLine("dir video")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("tag")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("tag ebay")) !is null);
    assert ((cast(TagAccountCommand)inter.parseLine("tag ebay trade")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("untag")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("untag ebay")) !is null);
    assert ((cast(UntagAccountCommand)inter.parseLine("untag ebay trade")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("del")) !is null);
    assert ((cast(DelCategoryCommand)inter.parseLine("del cat")) !is null);
    assert ((cast(UnknownCommand)inter.parseLine("remove")) !is null);
    assert ((cast(RemoveAccountCommand)inter.parseLine("remove facebook")) !is null);

}


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

module leek.commands;

import core.stdc.stdlib;

import leek.account;
import leek.io;

import std.algorithm;
import std.array;
import std.string;


/**
 * The Command design pattern base interface.
 */
interface Command
{
    /**
     * Executes the command code.
     *
     * Params:
     *     mgr = The Account manager to target.
     *
     * Returns:
     *     true if the account manager was modified by the command, 
     *     false otherwise.
     */
    bool execute(AccountManager mgr, IO io);
}

/**
 * The Command that adds an account.
 */
class AddAccountCommand : Command
{
public:
    this(string accountName)
    {
        this.accountName = accountName;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        if (mgr.hasAccount(accountName))
        {
            io.display("\nError: an account with the same name already exists\n");
            return false;
        }

        auto login = io.input("\nEnter login: ");
        auto password = io.input_password("\nEnter password: ");
        auto password2 = io.input_password("\nEnter password (confirmation): ");
        
        if (password != password2)
        {
            io.display("\nError: passwords do not match\n");
            return false;
        }
        mgr.addAccount(accountName, login, password);
        io.display("\nPassword added successfully\n");
        return true;
    }

private:
    string accountName;
}

/**
 * The Command that returns info about an Account.
 */
class GetAccountCommand : Command
{
public:
    this(string accountName)
    {
        this.accountName = accountName;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        auto acc = mgr.getAccount(accountName);
        if (acc is null)
        {
            io.display("\nError: no account with name %s found.\n".format(accountName));
        }
        else
        {
            io.display("login: %s".format(acc.login));
            io.display("password: %s".format(acc.password));
        }
        return false;
    }

private:
    string accountName;
}

/**
 * The Command that lists all the accounts on the system.
 */
class ListAccountsCommand : Command
{
    public override bool execute(AccountManager mgr, IO io)
    {
        io.display("\nAccount list:\n");
        auto accounts = mgr.accounts.array.sort!((a, b) => a.name < b.name);
        foreach (acc; accounts)
        {
            io.display("%s\n".format(acc.name));
        }
        return false;
    }
}

/**
 * The Command that tags an account with a cateory
 */
class TagAccountCommand : Command
{
public:
    this(string accountName, string categoryName)
    {
        this.accountName = accountName;
        this.categoryName = categoryName;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        auto acc = mgr.getAccount(accountName);
        if (acc is null)
        {
            io.display("\n No account named %s".format(accountName));
            return false;
        }

        auto cat = mgr.addCategory(categoryName);
        acc.addCategory(cat);
        return true;
    }

private:
    string accountName;
    string categoryName;
}

/**
 * The Command that displays help to the user.
 */
class HelpCommand : Command
{
public:
    public override bool execute(AccountManager mgr, IO io)
    {
        io.display("Available commands:\n");
        io.display("\th[elp]\t\tDisplays this help\n");
        io.display("\tq[uit]\t\tExit Leek\n");
        io.display("\tlist\t\tLists all the accounts\n");
        io.display("\tadd ACCOUNT\tCreate a new account\n");
        io.display("\tget ACCOUNT\tGet account data\n");
        io.display("\ttag ACCOUNT CATEGORY\tTag an account to belong to a category\n");
        return false;
    }
}

/**
 * The Command that exits the application.
 */
class QuitCommand : Command
{
    public override bool execute(AccountManager mgr, IO io)
    {
        exit(0);
        return false;
    }
}

/**
 * The Command returned when the user input doesn't match anything.
 */
class UnknownCommand : Command
{
    public override bool execute(AccountManager mgr, IO io)
    {
        io.display("Unkwown command. type \"help\" or \"h\" for available commands.\n");
        return false;
    }
}


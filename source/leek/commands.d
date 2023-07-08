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

module leek.commands;

import core.stdc.stdlib;

import leek.account;
import leek.generator;
import leek.io;
import leek.validate;

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
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

    /**
     * Constructs an AddAccountCommand object.
     *
     * Params:
     *     accountName = The name of the account to add.
     */
    this(string accountName)
    {
        this.accountName = accountName;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        if (mgr.hasAccount(accountName))
        {
            io.display("Error: an account with the same name already exists\n");
            return false;
        }

        auto login = io.input("Enter login: ");
        auto password = io.inputPassword("\nEnter password (leave blank to generate): ");

        if (password.length) 
        {
            auto password2 = io.inputPassword("\nEnter password (confirmation): ");
        
            if (password != password2)
            {
                io.display("\nError: passwords do not match\n");
                return false;
            }
        }
        else
        {
            auto silentIO = new SilentIO;
            do 
            {
                password = generateNewPassword();
            } while (!validatePassword(password, silentIO));
        }

        mgr.addAccount(accountName, login, password);
        io.display("\nPassword added successfully\n");
        return true;
    }

private:
    string accountName;
}

unittest
{
    enum accountName = "account";
    enum loginName = "username";
    enum password = "password";

    // Test that a first AddAccountCommand effectively adds a new account.
    auto mgr = new LeekAccountManager();
    auto testIO = new TestIO(loginName, password);
    auto cmd = new AddAccountCommand(accountName);
    cmd.execute(mgr, testIO);

    auto accounts = mgr.accounts.array;
    assert (accounts.length == 1);
    assert (accounts[0].name == accountName);
    assert (accounts[0].login == loginName);
    assert (accounts[0].password == password);

    // Test that a second AddAccountCommand does not change anything.
    auto cmd2 = new AddAccountCommand(accountName);
    auto testIO2 = new TestIO("anotherUser", "anotherPassword");
    cmd2.execute(mgr, testIO2);

    accounts = mgr.accounts.array;
    assert (accounts.length == 1);
    assert (accounts[0].name == accountName);
    assert (accounts[0].login == loginName);
    assert (accounts[0].password == password);
} 

/**
 * The Command that returns info about an Account.
 */
class GetAccountCommand : Command
{
public:

    /**
     * Constructs a GetAccountCommand object.
     * 
     * Params:
     *     accountName = The name of the account to get.
     */
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
            io.display("login: %s\n".format(acc.login));
            io.display("password: %s\n".format(acc.password));
        }
        return false;
    }

private:
    string accountName;
}


unittest
{
    enum accountName = "stupid";
    enum loginName = "toto";
    enum password = "LOLILOL";

    auto mgr = new LeekAccountManager();
    mgr.addAccount(accountName, loginName, password);

    auto testIO = new TestIO(loginName, password);
    auto cmd = new GetAccountCommand(accountName);
    cmd.execute(mgr, testIO);

    assert (testIO.output.canFind("login: %s\n".format(loginName)));
    assert (testIO.output.canFind("password: %s\n".format(password)));
    cmd = new GetAccountCommand("inexisting_Account");
    testIO = new TestIO(loginName, password);
    cmd.execute(mgr, testIO);
    assert (testIO.output.canFind!(line => line.startsWith("\nError: no account")));
}


/**
 * The Command that lists all the accounts on the system.
 */
class ListAccountsCommand : Command
{
public:
    /**
     * Constructs a ListAccountCommand object that lists the categories.
     */
    this()
    {
    }

    /**
     * Constructs a ListAccountCommand object that lists the accounts in a category. 
     *
     * Params:
     *     categoryName = The name of the category to list accounts for.
     */
    this(string categoryName)
    {
        this.categoryName = categoryName;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        if (categoryName is null)
        {
            return listAllAccounts(mgr, io);
        }
        else
        {
            return listAccountsInCategory(mgr, io);
        }
    }

private:
    string categoryName;

    bool listAllAccounts(AccountManager mgr, IO io)
    {
        io.display("\nAccount list:\n");
        auto accounts = mgr.accounts.array.sort!((a, b) => a.name < b.name);
        foreach (acc; accounts)
        {
            io.display("%s\n".format(acc.name));
        }
        return false;
    }

    bool listAccountsInCategory(AccountManager mgr, IO io)
    {
        auto cat = mgr.getCategory(categoryName);
        if (cat is null)
        {
            io.display("\nNo category named %s found.".format(categoryName));
        }
        else
        {
            auto accounts = cat.accounts.array.sort!((a, b) => a.name < b.name);
            foreach (acc; accounts)
            {
                io.display("%s\n".format(acc.name));
            }
        }
        return false;
    }

}


unittest
{
    enum accountName = "account";
    enum loginName = "login";
    enum password = "password";
    auto mgr = new LeekAccountManager();
    
    foreach (i; 0 .. 10)
    {
        mgr.addAccount("%s%s".format(accountName, i), loginName, password);
    }

    auto cmd = new ListAccountsCommand;
    auto testIO = new TestIO("", "");
    cmd.execute(mgr, testIO);
    foreach (i; 0 .. 10)
    {
        assert (testIO.output.canFind("%s%s\n".format(accountName, i)));
    }
}


/**
 * The commands that lists Categories and the accounts that belong to them.
 */
class ListCategoriesCommand : Command
{
    /**
     * Constructs a ListCategoriesCommand object that lists the categories.
     */
    public this()
    {

    }

    public override bool execute(AccountManager mgr, IO io)
    {
        auto categories = mgr.categories.array.sort!((a, b) => a.name < b.name);
        foreach (cat; categories)
        {
            io.display("%s\n".format(cat.name));
        }
        return false;
    }
}


unittest
{
    enum accountName = "account";
    enum loginName = "login";
    enum password = "password";
    auto mgr = new LeekAccountManager();
    mgr.addAccount(accountName, loginName, password);

    foreach (i; 0 .. 10)
    {
        mgr.addCategory("cat%s".format(i));
    }

    auto cmd = new ListCategoriesCommand;
    auto testIO = new TestIO("", "");
    cmd.execute(mgr, testIO);

    foreach (i; 0 .. 10)
    {
        assert (testIO.output.canFind("cat%s\n".format(i)));
    }
}


/**
 * The Command that tags an account with a category
 */
class TagAccountCommand : Command
{
public:

    /**
     * Constructs a TagAccountCommand object.
     *
     * Params:
     *     accountName = The target account name, must exist.
     *     categoryName = The category (created if not exists).
     */
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
            io.display("\nNo account named %s".format(accountName));
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
 * The Command that untags an account with a category.
 */
class UntagAccountCommand : Command
{
public:

    /**
     * Constructs a TagAccountCommand object.
     *
     * Params:
     *     accountName = The target account name, must exist.
     *     categoryName = The category (created if not exists).
     */
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
            io.display("\nNo account named %s".format(accountName));
            return false;
        }

        auto cat = mgr.getCategory(categoryName);
        if (cat is null)
        {
            io.display("\nNo category named %s".format(categoryName));
            return false;
        }

        acc.removeCategory(cat);
        return true;
    }
private:
    string accountName;
    string categoryName;
}

/**
 * The command that deletes a Category.
 */
class RemoveCategoryCommand : Command
{
public:

    /**
     * Constructs a RemoveCategoryCommand object.
     */
    this(string categoryName)
    {
        this.categoryName = categoryName;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        auto cat = mgr.getCategory(categoryName);
        if (cat is null)
        {
            io.display("\nNo category named %s".format(categoryName));
            return false;
        }
        
        foreach (acc; cat.accounts)
        {
            acc.removeCategory(cat);
        }

        mgr.remove(cat);
        return true;
    }


private:
    string categoryName;
}

/**
 * The command that removes an account.
 */
class RemoveAccountCommand : Command
{
public:
    /**
     * Constructs a RemoveAccountCommand.
     *
     * Params:
     *     accountName = The name of the account to remove.
     */
    this(string accountName)
    {
        this.accountName = accountName;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        auto acc = mgr.getAccount(accountName);
        if (acc is null)
        {
            io.display("\nNo account named %s".format(accountName));
            return false;
        }

        mgr.remove(acc);
        return true;
    }
private:
    string accountName;
}

/**
 * The command that changes an account password
 */
class ChangePasswordCommand : Command
{
    /**
     * Constructs a ChangePasswordCommand that generates 
     * a new password.
     *
     * Params:
     *     accountName = The name of the account to change.
     */
    this(string accountName)
    {
        this.accountName = accountName;
    }

    /**
     * Constructs a ChangePasswordCommand that generates 
     * a new password.
     *
     * Params:
     *     accountName = The name of the account to change.
     */
    this(string accountName, string newPassword)
    {
        this.accountName = accountName;
        this.newPassword = newPassword;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        auto acc = mgr.getAccount(accountName);
        if (acc is null)
        {
            io.display("\nNo account named %s".format(accountName));
            return false;
        }

        if (newPassword is null)
        {
            auto silentIO = new SilentIO;
            do 
            {
                newPassword = generateNewPassword();
            } while (!validatePassword(newPassword, silentIO));
        }
        else
        {
            if (!validatePassword(newPassword, io))
                return false;
        }

        mgr.changePassword(acc, newPassword);
        io.display("\n%s".format(newPassword));
        return true;
    }

private:
    
    string accountName;
    string newPassword;
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
        io.display("\tlist-accounts\t\tLists all the accounts\n");
        io.display("\tdir\t\tLists all the categories\n");
        io.display("\tdir CATEGORY\t\tLists all the accounts in category\n");
        io.display("\tadd ACCOUNT\tCreate a new account\n");
        io.display("\tget ACCOUNT\tGet account data\n");
        io.display("\ttag ACCOUNT CATEGORY\tTag an account to belong to a category\n");
        io.display("\tuntag ACCOUNT CATEGORY\tUntag a category from an account\n");
        io.display("\tremove-category CATEGORY\tRemoves a category (untags all tagged accounts)\n");
        io.display("\tremove-account ACCOUNT\tRemoves an account");
        io.display("\texport FILENAME\tExport database to a file.");
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

/**
 * Command that exports an account database to a plain text file.
 */
class ExportCommand : Command
{
public:
    this(string filename)
    {
        m_filename = filename;
    }

    override bool execute(AccountManager mgr, IO io)
    {
        io.display("Exporting password database to %s...\n".format(m_filename));
        auto f = File(m_filename, "w");
        foreach (acc; mgr.accounts)
        {
            string categories = acc.categories
                                   .map!(cat => cat.name)
                                   .joiner("\t")
                                   .to!string;
            f.writefln("%s\t%s\t%s\t%s", acc.name, acc.login, acc.password, categories);
        }
        return false;
    }

private:
    string m_filename;
}

private:
string generateNewPassword()
{
    auto candidates = candidatesFactory(true, true, true, true);
    return generatePassword(candidates, 14);
}



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

module leek.commands;

import core.stdc.stdlib;

import leek.account;
import leek.generator;
import leek.io;
import leek.validate;

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
 * The commands that lists Categories and the accounts that belong to them.
 */
class DirCommand : Command
{
    /**
     * Constructs a DirCommand object that lists the categories.
     */
    public this()
    {

    }

    /**
     * Constructs a DirCommand object that lists the accounts in a category. 
     *
     * Params:
     *     categoryName = The name of the category to list accounts for.
     */
    public this(string categoryName)
    {
        this.categoryName = categoryName;
    }

    public override bool execute(AccountManager mgr, IO io)
    {
        if (categoryName is null)
        {
            listCategories(mgr, io);
        }
        else
        {
            listAccountsInCategory(mgr, io);
        }
        return false;
    }

private:
    void listCategories(AccountManager mgr, IO io)
    {
        auto categories = mgr.categories.array.sort!((a, b) => a.name < b.name);
        foreach (cat; categories)
        {
            io.display("%s\n".format(cat.name));
        }
    }

    void listAccountsInCategory(AccountManager mgr, IO io)
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
    }

    string categoryName;
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
class DelCategoryCommand : Command
{
public:

    /**
     * Constructs a DelCategoryCommand object.
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
        return true;
    }

private:
    string generateNewPassword()
    {
        auto candidates = candidatesFactory(true, true, true, true);
        return generatePassword(candidates, 14);
    }

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
        io.display("\tlist\t\tLists all the accounts\n");
        io.display("\tdir\t\tLists all the categories\n");
        io.display("\tdir CATEGORY\t\tLists all the accounts in category\n");
        io.display("\tadd ACCOUNT\tCreate a new account\n");
        io.display("\tget ACCOUNT\tGet account data\n");
        io.display("\ttag ACCOUNT CATEGORY\tTag an account to belong to a category\n");
        io.display("\tuntag ACCOUNT CATEGORY\tUntag a category from an account\n");
        io.display("\tdel CATEGORY\tDeletes a category (untags all tagged accounts)\n");
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


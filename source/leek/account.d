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

module leek.account;

import std.algorithm;
import std.array;
import std.exception;
import std.range;

/**
 * A user account to store the password for.
 */
interface Account
{
    /**
     * Name of the account (e.g. 'Amazon')
     */
    string name() const;

    /**
     * Login of the account.
     */
    string login() const;

    /**
     * Password of the account.
     */
    string password();
}


/**
 * A category an account may belong to. 
 */
interface Category
{
    string name() const;
}


/**
 * Manages a set of accounts.
 */
interface AccountManager
{
    /**
     * Add an Account to this manager and returns it.
     */
    Account addAccount(string name, string login, string password);

    /**
     * Get an Account by its name
     */
    Account getAccount(string name);

    /**
     * Change the name of an account. 
     */
    void rename(Account account, string newName);

    /**
     * Remove an account.
     */
    void remove(Account);

    /**
     * Add a new category to this manager and returns it. 
     */
    Category addCategory(string name);

    /**
     * Returns the categories managed.
     */
    Category[] categories();
}

/**
 * Deals with errors concerning accounts. 
 */
class AccountException : Exception
{
    public this(string name)
    {
        super(name);
    }
}

private:


/**
 * Actual implementation of the AccountManager interface
 *
 */
class LeekAccountManager : AccountManager
{
public:
    override Account addAccount(string name, string login, string password)
    {
        auto found = m_accounts.byValue.find!(a => a.name == name);
        if (!found.empty)
            throw new AccountException("An account with the same name exists");

        m_accounts[nextId] = AccountImpl(name, login, password);
        auto proxy = new AccountProxy(this, nextId);
        nextId++;
        return proxy;
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        Account account = lam.addAccount("Amazon", "JohnDoe", "password123");
        assert (account !is null);
        assert (account.name == "Amazon");
        assert (account.login == "JohnDoe");
        assert (account.password == "password123");
        assertThrown!AccountException(lam.addAccount("Amazon", "John", "doe"));
    }

    override Account getAccount(string name)
    {
        auto found = m_accounts.byPair.find!(p => p[1].name == name);
        if (!found.empty)
        {
            return new AccountProxy(this, found.front[0]);
        }
        return null;
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        lam.addAccount("Amazon", "JohnDoe", "password123");
        auto account = lam.getAccount("Amazon");
        assert (account !is null);
        assert (account.name == "Amazon");
        assert (account.login == "JohnDoe");
        assert (lam.getAccount("Google") is null);
    }

    override void rename(Account account, string newName)
    in
    {
        assert (account !is null);
        assert (newName !is null);
        assert (newName.length > 0);
    }
    out
    {
        assert (account.name == newName);
    }
    body
    {
        auto proxy = cast(AccountProxy)account;
        if (proxy is null)
        {
            throw new AccountException("Invalid account.");
        }

        auto pimpl = proxy.id in m_accounts;
        if (pimpl is null)
        {
            throw new AccountException("Invalid account.");
        }

        pimpl.name = newName;
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        lam.addAccount("amazon", "JohnDoe", "password123");
        auto account = lam.getAccount("amazon");
        lam.rename(account, "Amazon");
        assert (account.name == "Amazon");
    }

    override void remove(Account account)
    in
    {
        assert (account !is null);
    }
    body
    {
        auto proxy = cast(AccountProxy)account;
        if (proxy is null)
        {
            throw new AccountException("Invalid account.");
        }

        m_accounts.remove(proxy.id);
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        lam.addAccount("amazon", "JohnDoe", "password123");
        auto account = lam.getAccount("amazon");
        lam.remove(account);
        assert (lam.getAccount("amazon") is null);
        assertThrown!AccountException(lam.rename(account, "Amazon"));
    }

    override Category addCategory(string name)
    {
        auto found = m_categories.byPair.find!(p => p[1] == name);
        if (!found.empty)
        {
            return new CategoryProxy(this, found.front[0]);
        }
        
        m_categories[nextId] = name;
        auto cat = new CategoryProxy(this, nextId);
        nextId++;
        return cat;
    }

    unittest
    {
        auto lam = new LeekAccountManager();
        auto cat1 = lam.addCategory("1");
        assert (cat1 !is null);
        assert (cat1.name == "1");
        auto cat2 = lam.addCategory("1");
        assert (cat1.name == cat2.name);
    }

    override Category[] categories()
    {
        auto cats = m_categories.keys
                                .map!(i => new CategoryProxy(this, i))
                                .array;
        return cast(Category[]) cats;
    }

private:
    struct AccountImpl
    {
        string name;
        string login;
        string password;
    }

    string accountNameFor(uint id) const 
    {
        return m_accounts[id].name;
    }

    string accountLoginFor(uint id) const 
    {
        return m_accounts[id].login;
    }

    string accountPasswordFor(uint id) const
    {
        return m_accounts[id].password;
    }

    string categoryNameFor(uint id) const 
    {
        return m_categories[id];
    }

    uint nextId;
    AccountImpl[uint] m_accounts;
    string[uint] m_categories;
}




class AccountProxy : Account
{
public:
    this(LeekAccountManager manager, uint id)
    {
        this.manager = manager;
        this.id = id;
    }

    override string name() const
    {
        return manager.accountNameFor(id);
    }

    override string login() const
    {
        return manager.accountLoginFor(id);
    }

    override string password() const
    {
        return manager.accountPasswordFor(id);
    }

private:

    LeekAccountManager manager;
    immutable uint id;
}


class CategoryProxy : Category
{
public:
    this(LeekAccountManager manager, uint id)
    {
        this.manager = manager;
        this.id = id;
    }

    override string name() const 
    {
        return manager.categoryNameFor(id);
    }

private:
    LeekAccountManager manager;
    immutable uint id;
}





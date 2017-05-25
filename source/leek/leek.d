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

module leek.leek;

import std.array;


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
    string password() const;
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
     * Returns the categories managed.
     */
    string[] categories() const;
}


private:


/**
 * Actual implementation of the AccountManager class
 *
 */
class LeekAccountManager : AccountManager
{
public:
    override Account addAccount(string name, string login, string password)
    {
        m_accounts[nextId] = AccountImpl(name, login, password);
        auto proxy = new AccountProxy(this, nextId);
        nextId++;
        return proxy;
    }

    override string[] categories() const
    {
        return m_categories.values.dup;
    }

private:
    struct AccountImpl
    {
        string name;
        string login;
        string password;
    }

    string nameFor(uint id) const 
    {
        return m_accounts[id].name;
    }

    string loginFor(uint id) const 
    {
        return m_accounts[id].login;
    }

    string passwordFor(uint id) const
    {
        return m_accounts[id].password;
    }

    uint nextId;
    AccountImpl[uint] m_accounts;
    string[uint] m_categories;
}

unittest
{
    auto lam = new LeekAccountManager;
    Account account = lam.addAccount("Amazon", "JohnDoe", "password123");
    assert (account !is null);
    assert (account.name == "Amazon");
    assert (account.login == "JohnDoe");
    assert (account.password == "password123");
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
        return manager.nameFor(id);
    }

    override string login() const
    {
        return manager.loginFor(id);
    }

    override string password() const
    {
        return manager.passwordFor(id);
    }

private:

    LeekAccountManager manager;
    const uint id;
}




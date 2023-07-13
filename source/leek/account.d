/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Copyright 2017-2023 Olivier Pisano.
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

module leek.account;

import core.exception;

import std.algorithm;
import std.array;
import std.exception;
import std.range;

@safe: 

struct Account
{
    this(ref return scope Account rhs)
    {
        name = rhs.name;
        login = rhs.login;
        password = rhs.password;
        url = rhs.url;
        notes = rhs.notes;
        categories = rhs.categories.dup;
    }

    void addCategory(in Category category)
    {
        categories ~= category.id;
    }

    string name;
    string login;
    string password;
    string url;
    string notes;
    uint[] categories;
}

struct Category
{
    uint id;
    string name;
}

struct AccountManager
{
    /**
     * Returns true if this manager has an account with this name, false 
     * otherwise.
     * 
     * Params:
     *     name = The account name.
     * 
     */
    bool hasAccount(scope string name)
    {
        return (name in m_accounts) != null;
    }

    /**
     * Returns true if this manager has a category with this name, false
     * otherwise.
     * 
     * Params:
     *     name = The category name.
     */
    bool hasCategory(scope string name)
    {
        return m_categories.canFind!(c => c.name == name);
    }

    /**
     * Add an Account to this manager and returns it. If an account with the
     * same name already exists, an AccountException will be thrown.
     *
     * Params:
     *     account = An account structure to add to this manager.
     * 
     * Throws:
     *     AccountException if account could not be added.
     */
    void addAccount(Account account)
    {
        Account* pAcc = (account.name in m_accounts);

        if (pAcc != null)
        {
            throw new AccountException("Account " ~ account.name ~ " already exist");
        }

        m_accounts[account.name] = account;
    }

    void addCategory(Category category)
    {
        if (m_categories.canFind!(c => c.name == category.name))
        {
            throw new AccountException("Category " ~ category.name ~ " already exist");
        }

        m_categories ~= category;
    }

    /** 
     * Search for accounts with a given name.
     * 
     * Params:
     *     string = name of account to search 
     *     account = Contains details about account found.
     * 
     * Returns:
     *     true if account is found, false otherwise.
     */
    bool findAccount(scope string name, out Account account)
    {
        Account* pAcc = name in m_accounts;

        if (pAcc == null)
        {
            return false;
        }

        account = *pAcc;
        return true;
    }

    /**
     * Get a Category by its name.
     *
     * Params:
     *    name = The category name, identifying it.
     *    category = Contains details about category found
     * 
     * Returns:
     *     true if category is found, false otherwise.
     */
    bool findCategory(scope string name, out Category cat) const
    {
        auto found = m_categories.find!(c => c.name == name);

        if (found.empty)
        {
            return false;
        }

        cat = found.front;
        return true;
    }

    /** 
     * Rename an account.
     * 
     * Params
     *     name = old name 
     *     newName = new name 
     */ 
    void renameAccount(scope string name, string newName)
    {
        Account *pAcc = name in m_accounts;

        if (pAcc == null)
        {
            throw new AccountException("Account " ~ name ~ " does not exist");
        }

        Account temp = *pAcc;
        m_accounts.remove(name);
        temp.name = newName;
        m_accounts[newName] = temp;
    }

    void updateAccount(scope string name, Account account)
    {
        Account *pAcc = name in m_accounts;

        if (pAcc == null)
        {
            throw new AccountException("Account " ~ name ~ " does not exist");
        }

        Account temp = *pAcc;
        m_accounts.remove(name);
        temp = account;
        m_accounts[temp.name] = temp;
    }

    void removeAccount(scope string name)
    {
        m_accounts.remove(name);
    }

    void removeCategory(scope string name)
    {
        auto offset = m_categories.countUntil!(c => c.name == name);

        if (offset == -1)
        {
            throw new AccountException("Category " ~ name ~ " does not exist");
        }

        Category cat = m_categories[offset];

        foreach (ref account; m_accounts)
        {
            auto cat_offset = account.categories[].countUntil!(i => i == cat.id);
            if (cat_offset > -1)
            {
                account.categories = account.categories.remove(cat_offset);
            }
        }

        m_categories = m_categories.remove(offset);
    }


    auto categories()
    {
        return m_categories;
    }

    auto accounts()
    {
        return m_accounts.values();
    }

    auto accounts(scope string cat)
    {
        Category category;
        findCategory(cat, category);
        return m_accounts.values.filter!(a => a.categories.canFind(category.id));
    }

package:
    void addRecord(Account account)
    {
        m_accounts[account.name] = account;
    }

    void addRecord(Category category)
    {
        m_categories ~= category;
    }


private:
    Account[string] m_accounts;
    Category[] m_categories;
}

/**
 * Deals with errors concerning accounts. 
 */
class AccountException : Exception
{
    public this(string message)
    {
        super(message);
    }
}

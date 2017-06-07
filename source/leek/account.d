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

import core.exception;

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
     *
     * Throws:
     *     AccountException if this account was removed. 
     */
    string name() const;

    /**
     * Login of the account.
     *
     * Throws:
     *     AccountException if this account was removed.
     */
    string login() const;

    /**
     * Password of the account.
     *
     * Throws:
     *     AccountException if this account was removed.
     */
    string password() const;

    /**
     * The categories this account belongs to.
     */
    InputRange!Category categories();

    /**
     * Add a category to this account.
     *
     * Params:
     *     category = The category to add.
     *
     * Throws:
     *     AccountException if category is invalid.
     */
    void addCategory(Category category);

    /**
     * Removes a category from this account.
     *
     * Params:
     *     category = the category to remove.
     *
     * Throws:
     *     AccountException if category is invalid.
     */
    void removeCategory(Category category);
}


/**
 * A category an account may belong to, like a tag. 
 */
interface Category
{
    /**
     * Name of the category
     *
     * Throws:
     *     AccountException if this category was removed.
     */
    string name() const;

    /**
     * Returns the accounts belonging to this category.
     *
     */
    InputRange!Account accounts();
}


/**
 * Manages a set of accounts.
 */
interface AccountManager
{
    /**
     * Add an Account to this manager and returns it. If an account with the
     * same name already exists, an AccountException will be thrown.
     *
     * Params:
     *     name =     The account name, identifying it (must be unique). 
     *     login =    The user login 
     *     password = The user password.
     *
     * Returns:
     *     A object implementing the Account interface representing the newly
     *     created account.
     * 
     * Throws:
     *     AccountException if an account with the same name already exists.
     */
    Account addAccount(string name, string login, string password);

    /**
     * Get an Account by its name.
     *
     * Params:
     *     name = The account name, identifying it.
     *
     * Returns:
     *     The Account object with the name passed as parameter, or null if 
     *     no account with this name exists. 
     */
    Account getAccount(string name);

    /**
     * Change the name of an account.
     *
     * Params:
     *     account = The account to rename.
     *     newName = The new name of the account.
     *
     * Throws:
     *     AccountException if account is invalid.
     */
    void rename(Account account, string newName);

    /**
     * Change the password of an account.
     *
     * Params:
     *     account  = The account to change the password.
     *     password = The new password of the account.
     *
     * Throws:
     *     AccountException if the account is invalid.
     */
    void changePassword(Account account, string password);

    /**
     * Remove an account.
     *
     * Params:
     *     account = The account to remove.
     *
     * Throws:
     *     AccountException if account is invalid. 
     */
    void remove(Account account);

    /**
     * Add a new category to this manager and returns it.
     *
     * Params:
     *     name = The name of the category to add.
     */
    Category addCategory(string name);

    /**
     * Remove a category.
     * 
     * Params:
     *     category = The category to remove. 
     *
     * Throws:
     *     AccountException if category is invalid.
     */
    void remove(Category category);

    /**
     * Returns the categories managed.
     */
    InputRange!Category categories();    
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

AccountManager createAccountManager()
{
    return new LeekAccountManager;
}

package:


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

    override void changePassword(Account account, string password)
    in
    {
        assert (account !is null);
        assert (password !is null);
    }
    out
    {
        assert (account.password == password);
    }
    body
    {
        auto proxy = cast(AccountProxy) account;
        if (proxy is null)
        {
            throw new AccountException("Invalid account");
        }

        auto pimpl = proxy.id in m_accounts;
        if (pimpl is null)
        {
            throw new AccountException("Invalid account");
        }

        pimpl.password = password;
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        auto account = lam.addAccount("amazon", "JohnDoe", "password123");
        assert (account.password == "password123");
        lam.changePassword(account, "password123456");
        assert (account.password == "password123456");
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

    override void remove(Category category)
    in
    {
        assert (category !is null);
    }
    body
    {
        auto proxy = cast(CategoryProxy)category;
        if (proxy is null)
        {
            throw new AccountException("Invalid category");
        }

        m_categories.remove(proxy.id);
    }
    
    unittest
    {
        auto lam = new LeekAccountManager();
        auto cat1 = lam.addCategory("1");
        lam.remove(cat1);
        assertThrown!AccountException(cat1.name);
    }

    override InputRange!Category categories()
    {
        Category[] arr;
        foreach (uint id; m_categories.byKey)
        {
            arr ~= new CategoryProxy(this, id);
        }
        return m_categories.byKey
                           .map!(i => cast(Category)new CategoryProxy(this, i))
                           .inputRangeObject;
    }

    unittest
    {
        auto lam = new LeekAccountManager();
        lam.addCategory("Leisure");
        lam.addCategory("Business");
        lam.addCategory("Entertainment");

        assert (lam.categories.canFind!(c => c.name == "Leisure"));
        assert (lam.categories.canFind!(c => c.name == "Business"));
        assert (lam.categories.canFind!(c => c.name == "Entertainment"));
    }


package:

    /**
     * Returns an input range of CategoryRecord for storing this 
     * AccountManager state.
     */
    auto categoryRecords() 
    {
        return m_categories.byPair
                           .map!(p => CategoryRecord(p[0], p[1]));
    }

    /**
     * Returns an input range of AccountRecord for storing this 
     * AccountManager state.
     */
    auto accountRecords()
    {
        return m_accounts.byValue
                         .map!(a => AccountRecord(a.name,
                                                  a.login,
                                                  a.password,
                                                  a.categories));
    }

    /**
     * Add an account from an AccountRecord object.
     */
    void addAccount(AccountRecord record)
    {
        m_accounts[nextId] = AccountImpl(record.name,
                                         record.login,
                                         record.password,
                                         record.categories);
        nextId++;
    }

private:
    /**
     * The structure that is really holding account information.
     */
    struct AccountImpl
    {
        string name;
        string login;
        string password;
        uint[] categories;
    }

    /**
     * Returns the name of the account identified by id.
     */
    string accountNameFor(uint id) const 
    {
        auto p_account = id in m_accounts;
        if (p_account)
        {
            return p_account.name;
        }
        throw new AccountException("Invalid account");
    }

    /**
     * Returns the login of the account identified by id.
     */
    string accountLoginFor(uint id) const 
    {
        auto p_account = id in m_accounts;
        if (p_account)
        {
            return p_account.login;
        }
        throw new AccountException("Invalid account");
    }

    /**
     * Returns the password of the account identified by id.
     */
    string accountPasswordFor(uint id) const
    {
        auto p_account = id in m_accounts;
        if (p_account)
        {
            return p_account.password;
        }
        throw new AccountException("Invalid account");
    }

    /**
     * Returns the name of the category identified by id.
     */
    string categoryNameFor(uint id) const 
    {
        auto p_category = id in m_categories;
        if (p_category)
        {
            return *p_category;
        }
        throw new AccountException("Invalid category");
    }

    /**
     * Returns the categories the account with given id belongs to.
     */
    InputRange!Category categoriesFor(uint id)
    {
        auto pimpl = id in m_accounts;
        if (pimpl is null)
        {
            throw new AccountException("Invalid account");
        }

        return pimpl.categories
                    .map!(i => cast(Category) new CategoryProxy(this, i))
                    .inputRangeObject;
    }

    /**
     * Add a Category to an account.
     */
    void addCategoryFor(uint accountId, uint categoryId)
    {
        auto pimpl = accountId in m_accounts;
        if (pimpl is null)
        {
            throw new AccountException("Invalid account");
        }

        if (!pimpl.categories.canFind(categoryId))
        {
            pimpl.categories ~= categoryId;
        }
    }

    /**
     * Removes a category for an account.
     */
    void removeCategoryFor(uint accountId, uint categoryId)
    {
        auto pimpl = accountId in m_accounts;
        if (pimpl is null)
        {
            throw new AccountException("Invalid account");
        }

        pimpl.categories = pimpl.categories
                                .remove(pimpl.categories
                                             .countUntil(categoryId));
    }

    /**
     * Returns a list of accounts belonging to a category.
     */
    InputRange!Account accountsWithCategory(uint categoryId)
    {
        return m_accounts.byPair
                         .filter!(p => p[1].categories
                                           .canFind(categoryId))
                         .map!(p => cast(Account)new AccountProxy(this, p[0]))
                         .inputRangeObject;
    }

    uint nextId;
    AccountImpl[uint] m_accounts;
    string[uint] m_categories;
}


/**
 * Implementation of the Account interface. These are the objects atually 
 * returned by the LeekAccountManager class. 
 *
 * This class only contains a pointer to the LeekAccountManager that 
 * created it an a numerical identifier to the account referred to. 
 */
class AccountProxy : Account
{
public:

    /**
     * Constructs an AccountProxy object. 
     *
     * Params:
     *     manager = The LeekAccountManager instance creating this object.
     *     id      = The numerical id identifying the account this proxy 
     *               refers to.
     */
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

    override InputRange!Category categories()
    {
        return manager.categoriesFor(id);
    }

    override void addCategory(Category category) 
    {
        auto proxy = cast(CategoryProxy)category;
        if (proxy is null)
        {
            throw new AccountException("Invalid category");
        }

        manager.addCategoryFor(id, proxy.id);
    }

    override void removeCategory(Category category)
    {
        auto proxy = cast(CategoryProxy) category;
        if (proxy is null)
        {
            throw new AccountException("Invalid category");
        }

        manager.removeCategoryFor(id, proxy.id);
    }

private:
    LeekAccountManager manager;
    immutable uint id;
}

unittest 
{
    auto lam = new LeekAccountManager;
    auto acc = lam.addAccount("Netflix", "johndoe", "password123");
    auto entertainment = lam.addCategory("entertainment");
    auto streaming = lam.addCategory("streaming");
    acc.addCategory(entertainment);
    acc.addCategory(streaming);
    auto e = cast(CategoryProxy)entertainment;
    auto s = cast(CategoryProxy)streaming;
    assert (acc.categories.canFind!(c => c.name == "entertainment"));
    assert (acc.categories.canFind!(c => c.name == "streaming"));
    acc.removeCategory(entertainment);
    assert (!acc.categories.canFind!(c => c.name == "entertainment"));
    assert (acc.categories.canFind!(c => c.name == "streaming"));
    assert (streaming.accounts.canFind!(a => a.name == "Netflix"));
}

/**
 * Implementation of the Category interface. These are the objects atually 
 * returned by the LeekAccountManager class. 
 *
 * This class only contains a pointer to the LeekAccountManager that 
 * created it an a numerical identifier to the Category referred to. 
 */
class CategoryProxy : Category
{
public:
    /**
     * Constructs an CategoryProxy object. 
     *
     * Params:
     *     manager = The LeekAccountManager instance creating this object.
     *     id      = The numerical id identifying the category this proxy 
     *               refers to.
     */
this(LeekAccountManager manager, uint id)
    {
        this.manager = manager;
        this.id = id;
    }

    override string name() const 
    {
        return manager.categoryNameFor(id);
    }


    override InputRange!Account accounts()
    {
        return manager.accountsWithCategory(id);
    }

private:
    LeekAccountManager manager;
    immutable uint id;
}

package:

/**
 * Used for Category I/O
 */
struct CategoryRecord
{
    uint id;
    string name;
}

/**
 * Used for Account I/O
 */
struct AccountRecord
{
    string name;
    string login;
    string password;
    uint[] categories;
}

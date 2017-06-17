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
     * Returns true if this manager has an account with this name, false 
     * otherwise.
     * 
     * Params:
     *     name = The account name.
     * 
     */
    bool hasAccount(string name);

    /**
     * Returns true if this manager has a category with this name, false
     * otherwise.
     * 
     * Params:
     *     name = The category name.
     */
    bool hasCategory(string name);

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
     * Get a Category by its name.
     *
     * Params:
     *    name = The category name, identifying it.
     * 
     * Returns:
     *     The Category object with the name passe as parameter, or null if no
     *     category with this name exists.
     */
    Category getCategory(string name);

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

    /**
     * Returns the accounts managed.
     */
    InputRange!Account accounts();
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

    override bool hasAccount(string name)
    {
        auto found = m_accounts.find!(a => a.name == name);
        return (!found.empty);
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        Account account = lam.addAccount("Amazon", "JohnDoe", "password123");
        assert (lam.hasAccount(account.name));
        assert (!lam.hasAccount("LDLC"));
    }

    override bool hasCategory(string name)
    {
        auto found = m_categories.find(name);
        return (!found.empty);
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        auto cat = lam.addCategory("video");
        assert (lam.hasCategory(cat.name));
        assert (!lam.hasCategory("non-existent category"));
    }
    
    override Category getCategory(string name)
    {
        size_t index = m_categories.countUntil(name);
        if (index == -1 || index > uint.max)
            return null;
        else
            return new CategoryProxy(this, cast(uint)index);
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        lam.addCategory("video");
        auto cat = lam.getCategory("video");
        assert(cat.name == "video");
        auto cat2 = lam.getCategory("non-existent category");
        assert (cat2 is null);
   
    }

    override Account addAccount(string name, string login, string password)
    {
        auto found = m_accounts.canFind!(a => a.name == name);
        if (found)
            throw new AccountException("An account with the same name exists");

        auto nextAccId = cast(uint) m_accounts.length;
        m_accounts ~= AccountImpl(name, login, password);
        auto proxy = new AccountProxy(this, nextAccId);
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
        auto index  = m_accounts.countUntil!(a => a.name == name);
        if (index != -1 && index <= uint.max)
        {
            return new AccountProxy(this, cast(uint)index);
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

        if (proxy.id >= m_accounts.length 
                || m_accounts[proxy.id] == AccountImpl.init)
        {
            throw new AccountException("Invalid account.");
        }

        m_accounts[proxy.id].name = newName;
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

        if (proxy.id >= m_accounts.length 
                || m_accounts[proxy.id] == AccountImpl.init)
        {
            throw new AccountException("Invalid account");
        }

        m_accounts[proxy.id].password = password;
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

        m_accounts[proxy.id] = AccountImpl.init;
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
        auto index = m_categories.countUntil(name);
        if (index != -1 && index <= uint.max)
        {
            return new CategoryProxy(this, cast(uint)index);
        }
       
        auto nextCatId = cast(uint)m_categories.length;
        m_categories ~= name;
        auto cat = new CategoryProxy(this, nextCatId);
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

        m_categories[proxy.id] = string.init;
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
        return m_categories.take(uint.max)
                           .enumerate
                           .filter!(t => t[1] != string.init)
                           .map!(t => cast(uint)t[0])
                           .map!(i => cast(Category)new CategoryProxy(this, i))
                           .inputRangeObject;
    }

    unittest 
    {
        auto lam = new LeekAccountManager();
        lam.addCategory("Leisure");
        lam.addCategory("Business");
        lam.addCategory("Entertainment");

        assert (lam.categories.find!(c => c.name == "Leisure"));
        assert (lam.categories.canFind!(c => c.name == "Business"));
        assert (lam.categories.canFind!(c => c.name == "Entertainment"));
    }

    override InputRange!Account accounts()
    {
        return m_accounts.take(uint.max)
                         .enumerate
                         .filter!(t => t[1] != AccountImpl.init)
                         .map!(t => cast(uint)t[0])
                         .map!(i => cast(Account)new AccountProxy(this, i))
                         .inputRangeObject;
    }

    unittest
    {
        auto lam = new LeekAccountManager;
        lam.addAccount("amazon", "JohnDoe", "password123");
        lam.addAccount("netflix", "RobertSmith", "qwerty123");

        assert (lam.accounts.canFind!(a => a.name == "amazon"));
        assert (lam.accounts.canFind!(a => a.name == "netflix"));
    }


package:

    /**
     * Returns an input range of CategoryRecord for storing this 
     * AccountManager state.
     */
    auto categoryRecords() 
    {
        return m_categories.take(uint.max)
                           .enumerate
                           .filter!(t => t[1] != string.init)
                           .map!(t => CategoryRecord(cast(uint)t[0], t[1]));
    }

    /**
     * Returns an input range of AccountRecord for storing this 
     * AccountManager state.
     */
    auto accountRecords()
    {
        return m_accounts.take(uint.max)
                         .filter!(a => a != AccountImpl.init)
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
        m_accounts ~= AccountImpl(record.name,
                                  record.login,
                                  record.password,
                                  record.categories);
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
        if (id <= m_accounts.length && m_accounts[id].name != string.init)
        {
            return m_accounts[id].name;
        }
        throw new AccountException("Invalid account");
    }

    /**
     * Returns the login of the account identified by id.
     */
    string accountLoginFor(uint id) const 
    {
        if (id <= m_accounts.length && m_accounts[id].name != string.init)
        {
            return m_accounts[id].login;
        }
        throw new AccountException("Invalid account");
    }

    /**
     * Returns the password of the account identified by id.
     */
    string accountPasswordFor(uint id) const
    {
        if (id <= m_accounts.length && m_accounts[id].name != string.init)
        {
            return m_accounts[id].password;
        }
        throw new AccountException("Invalid account");
    }

    /**
     * Returns the name of the category identified by id.
     */
    string categoryNameFor(uint id) const 
    {
        if (id <= m_categories.length && m_categories[id] != string.init)
        {
            return m_categories[id];
        }
        throw new AccountException("Invalid category");
    }

    /**
     * Returns the categories the account with given id belongs to.
     */
    InputRange!Category categoriesFor(uint id)
    {
        if (id <= m_accounts.length && m_accounts[id].name != string.init)
        {
            return m_accounts[id].categories
                                 .take(uint.max)
                                 .filter!(i => m_categories[i] != string.init)
                                 .map!(i => cast(uint)i)
                                 .map!(i => cast(Category) new CategoryProxy(this,
                                                                             i))
                                 .inputRangeObject;
        }
            throw new AccountException("Invalid account");
    }

    /**
     * Add a Category to an account.
     */
    void addCategoryFor(uint accountId, uint categoryId)
    {
        if (accountId <= m_accounts.length 
                && m_accounts[accountId] != AccountImpl.init)
        {
            if (!m_accounts[accountId].categories.canFind(categoryId))
            {
                m_accounts[accountId].categories ~= categoryId;
            }
        }
        else
        {
            throw new AccountException("Invalid account");
        }
    }

    /**
     * Removes a category for an account.
     */
    void removeCategoryFor(uint accountId, uint categoryId)
    {
        if (accountId <= m_accounts.length 
                && m_accounts[accountId] != AccountImpl.init)
        {
            auto pacc = &m_accounts[accountId];
            pacc.categories = pacc.categories
                                  .remove(pacc.categories
                                              .countUntil(categoryId));
        }
        else
        {
            throw new AccountException("Invalid account");
        }
    }

    /**
     * Returns a list of accounts belonging to a category.
     */
    InputRange!Account accountsWithCategory(uint categoryId)
    {
        return m_accounts.take(uint.max)
                         .enumerate
                         .filter!(t => t[1].categories
                                           .canFind(categoryId))
                         .map!(t => cast(uint)t[0])
                         .map!(i => cast(Account)new AccountProxy(this, i))
                         .inputRangeObject;
    }

    AccountImpl[] m_accounts;
    string[] m_categories;
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

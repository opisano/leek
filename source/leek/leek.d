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
     * Returns the categories. 
     */
    string[] categories();

    /**
     * Returns a list of the accounts in a categroy.
     */
    Account[] accounts(string category);
}

private:


class LeekAccountManager : AccountManager
{
public:

};

class AccountProxy : Account
{
public:
    this(AccountManager manager, uint id)
    {
        this.manager = manager;
        this.id = id;
    }

    override string name() const
    {
    }

    override string login() const
    {
    }

    override string password() const
    {
    }

private:
    AccountManager manager;
    const uint id;
}

class ConcreteAccount: Account
{
public:
    this(string accountName, string userLogin, string userPassword)
    {
        m_accountName = accountName;
        m_userLogin = userLogin;
        m_userPassword = userPassword;
    }

    override string name() const 
    {
        return m_accountName;
    }

    override string login() const 
    {
        return m_userLogin;
    }

    override string password() const 
    {
        return m_userPassword;
    }

    void setName(string newName)
    {
        m_accountName = newName;
    }

    void setPassword(string newPassword)
    {
        m_userPassword = userPassword;
    }

private:
    string m_accountName;
    string m_userLogin;
    string m_userPassword;
}



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

module leek.generator;

import std.random;

public:

/**
 * Provides the interface of the candidate characters for the generator.
 */
interface Candidates
{
    /**
     * Returns the candidate characters for the generator as a string 
     * of characters.
     */
    string candidates() const pure;
}


/**
 * Returns a Candidates object that provides the options according 
 * to the parameters specified.
 *
 * Parameters:
 *     lower = include lowercase characters.
 *     upper = include uppercase characters.
 *     digits = include digits.
 *     special = include special characters.
 */
Candidates candidatesFactory(bool lower, bool upper, bool digits, bool special)
{
    Candidates result = new NoCandidates;

    if (lower)
        result = new LowerCase(result);
    if (upper)
        result = new UpperCase(result);
    if (digits)
        result = new Digit(result);
    if (special)
        result = new Special(result);
    
    return result;
}

/**
 * Generates a random password of length characters among the ones provided 
 * by the candidates object passed.
 */
string generatePassword(const Candidates candidates, size_t length)
in 
{
    assert (candidates !is null);
}
out (result)
{
    assert (result.length == length);
}
body
{
    string password;
    immutable characters = candidates.candidates;

    while (password.length < length)
    {
        size_t index = uniform(0, characters.length); 
        password ~= characters[index];
    }

    return password;
}

private:

/**
 * An implementation of the Candidates interface that does nothing.
 * Avoid having to check for null in the code.
 */
final class NoCandidates : Candidates
{
    /**
     * Returns an empty string.
     */
    public override string candidates() const pure 
    {
        return "";
    }
}


/**
 * An implementation of the Candidates interface that provides
 * lowercase characters.
 */
final class LowerCase: Candidates
{
public:
    /**
     * Constructs a LowerCase object, decorating another 
     * Candidates
     * 
     * Params:
     *     provider = The Candidateto decorate.
     */
    this(Candidates provider) 
    {
        m_wrapped = provider;
    }

    /**
     * Returns the lowercase characters as candidates.
     */
    override string candidates() const pure 
    {
        return m_wrapped.candidates() ~ "abcdefghijklmnopqrstuvwxyz";
    }

private:
    Candidates m_wrapped;
}


/**
 * An implementation of the Candidates interface that provides
 * uppercase characters.
 */
final class UpperCase: Candidates
{
public:
    /**
     * Constructs a LowerCase object, decorating another 
     * Candidates
     * 
     * Params:
     *     provider = The Candidate to decorate.
     */
    this(Candidates provider) 
    {
        m_wrapped = provider;
    }

    /**
     * Returns the uppercase characters as candidates.
     */
    override string candidates() const pure 
    {
        return m_wrapped.candidates() ~ "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    }

private:
    Candidates m_wrapped;
}


/**
 * An implementation of the Candidates interface that provides
 * digit characters.
 */
final class Digit: Candidates
{
public:
    /**
     * Constructs a Digit object, decorating another 
     * Candidates
     * 
     * Params:
     *     provider = The Candidates to decorate.
     */
    this(Candidates provider) 
    {
        m_wrapped = provider;
    }

    /**
     * Returns the digit characters as candidates.
     */
    override string candidates() const pure 
    {
        return m_wrapped.candidates() ~ "1234567890";
    }

private:
    Candidates m_wrapped;
}

final class Special : Candidates
{
public:
    /**
     * Constructs a Special object, decorating another 
     * Candidates
     * 
     * Params:
     *     provider = The Candidates to decorate.
     */
    this(Candidates provider) 
    {
        m_wrapped = provider;
    }

    override string candidates() const pure
    {
        return m_wrapped.candidates() ~ "\\#@$&%+/";
    }

private:
    Candidates m_wrapped;
}

version (unittest)
{
    import std.algorithm;
    import std.array;
}


unittest
{
    auto low = candidatesFactory(true, false, false, false);
    assert (low.candidates.canFind('a'));
}

unittest
{
    auto up = candidatesFactory(false, true, false, false);
    assert (up.candidates.canFind('A'));
}

unittest
{
    auto digit = candidatesFactory(false, false, true, false);
    assert (digit.candidates.canFind('0'));
}

unittest
{
    auto special = candidatesFactory(false, false, false, true); 
    assert (special.candidates.canFind('#'));
}

unittest
{
    auto letters = candidatesFactory(true, true, false, false);
    assert (letters.candidates.canFind('a'));
    assert (letters.candidates.canFind('A'));
    assert (!letters.candidates.canFind('0'));
    assert (!letters.candidates.canFind('#'));
}

unittest
{
    auto all = candidatesFactory(true, true, true, true);
    assert (all.candidates.canFind('a'));
    assert (all.candidates.canFind('A'));
    assert (all.candidates.canFind('0'));
    assert (all.candidates.canFind('#'));

}

unittest
{
    auto all = candidatesFactory(true, true, true, true);
    string[] passwords;
    foreach (i; 0 .. 1000)
        passwords ~= generatePassword(all, 16);
    foreach (password; passwords)
        assert (password.length == 16);
    string[] uniquePasswords = passwords.sort().uniq.array;
    assert (uniquePasswords.length == passwords.length);
}

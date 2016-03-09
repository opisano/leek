/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    This file is part of Leek.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

module leek.generator;

import std.container.array;
import std.random;

enum MAX_PASSWORD_LENGTH = 128u;


string generatePassword(uint length, bool lowercase, bool uppercase,
                        bool digits, bool special)
in
{
    assert (length < MAX_PASSWORD_LENGTH);
}
out (result)
{
    assert (result.length == length);
}
body
{
    char[MAX_PASSWORD_LENGTH] buffer;
    auto candidates = prepareCandidates(lowercase, uppercase, digits, special);
    
    foreach (i; 0 .. length)
    {
        uint index = std.random.uniform(0, cast(uint)candidates.length);
        buffer[i] = candidates[index];
    }

    return buffer[0 .. length].idup;
}

/**
 * Prepares the candidate characters for a password.
 * 
 * @param lowercase include lowercase ASCII characters.
 * @param uppercase include uppercase ASCII characters.
 * @param digits include 0-9 digits.
 * @param special include some special characters.
 *
 * Returns a range of char.
 */
private auto prepareCandidates(bool lowercase, bool uppercase,
                               bool digits, bool special)
{
    Array!char candidates;

    if (lowercase)
    {
        foreach (char c; "abcdefghijklmnopqrstuvwxyz")
            candidates.insert(c);
    }

    if (uppercase)
    {
        foreach (char c; "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            candidates.insert(c);
    }

    if (digits)
    {
        foreach (char c; "1234567890")
            candidates.insert(c);
    }

    if (special)
    {
        foreach (char c; "`~!@#$%^&*()_-+={}[]\\|:;\"\'<>,.?/")
            candidates.insert(c);
    }

    return candidates[];
}


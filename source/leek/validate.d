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

module leek.validate;

import std.algorithm;
import std.string;
import std.exception;


extern(C)
{

const(char)* CRACKLIB_DICTPATH;
const(char)* FascistCheck(const(char)* passwd, const(char)* dictpath);

}



/**
 * Checks that a password is reasonably valid.
 *
 * Params:
 *     password = the password to check.
 *     io       = A IO object to to interact with the user.
 *
 * Returns:
 *     true if the password is considered valid, false otherwise.
 */
bool validatePassword(string password, out string diagnostic)
{
    enum MIN_PASSWORD_LENGTH = 12;

    auto reason = FascistCheck(password.toStringz(), CRACKLIB_DICTPATH);
    if (reason != null)
    {
        diagnostic = fromStringz(reason).assumeUnique;
        return false;
    }

    return true;
}


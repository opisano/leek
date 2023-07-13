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

module leek.generator;

import std.random;

public:



/**
 * Generates a random password of length characters among the ones provided 
 * by the candidates object passed.
 */
string generatePassword(scope string candidates, size_t length)
in 
{
    assert (candidates !is null);
}
out (result)
{
    assert (result.length == length);
}
do
{
    string password;
    password.reserve(length);

    while (password.length < length)
    {
        size_t index = uniform(0, candidates.length); 
        password ~= candidates[index];
    }

    return password;
}


unittest
{
    string candidates = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789#$/@+-*=%";

    foreach (i; 0 .. 1000)
    {
        auto password = generatePassword(candidates, 16);
        assert (password.length == 16);
    }
}

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
    along with Leek.  If not, see <http://www.gnu.org/licenses/>.

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

import vibe.vibe;
import web;

void main(string[] args)
{
	auto settings = new HTTPServerSettings;
	settings.port = 4430;
	settings.bindAddresses = ["127.0.0.1"];
    settings.sessionStore = new MemorySessionStore;
    settings.tlsContext = createTLSContext(TLSContextKind.server);
    settings.tlsContext.useCertificateChainFile("server-cert.pem");
    settings.tlsContext.usePrivateKeyFile("server-key.pem");

    auto router = new URLRouter;
    router.registerWebInterface(new WebInterface);


	listenHTTP(settings, router);
    runApplication();
}






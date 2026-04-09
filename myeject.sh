#!/bin/bash

. ./settings.conf

drive="$1"
"$powershell" -Command "(New-Object -comObject Shell.Application).NameSpace(17).ParseName('$drive').InvokeVerb('Eject')"


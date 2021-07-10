#!/bin/bash
clish -c "installer uninstall Check_Point_CPcme_Bundle_R80_40_T83.tgz"

chmod +x /home/admin/user.def.FW1
mv $FWDIR/conf/user.def.FW1 $FWDIR/conf/user.def.FW1.bk
cp -p /home/admin/user.def.FW1 $FWDIR/conf/user.def.FW1

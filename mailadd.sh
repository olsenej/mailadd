####################################
#!/bin/bash
#
# Mojohost
# Script: mysqluadd.sh
#
# Description: Adds mail user. Asks how mail should be dealt with (forward, useraccount, both), then does it.
#
# Requires: revirt, newaliases
#
# Author: Edward Olsen
#
# Changelog:
# * 1/31/13: Edward Olsen
# - initial write
# * 2/3/13:  Edward
# - fleshing out functions

writeAndRevirt ()
{
        echo ""
        echo -e "$1 \t\t $2" >> /etc/mail/virtusertable
        cwd=`pwd`
        cd /etc/mail
#        `revirt`
        cd $cwd
        echo "Added $1 to $2"
        echo ""

}

checkForDuplicateEntries ()
{
        echo ""
        areyoustillthere="$(cat /etc/mail/virtusertable |awk '{print $1;}'|grep $1)"
        if [ "$areyoustillthere" == "$1" ]; then
                return 0        #Found a match in first column
        else
                return 1        #No match in first column
        fi
}

forwardMail ()
{
        echo ""
        read -p "Enter in email to forward from: " fromemail
        read -p "Enter in email to forward to: " toemail
        if checkForDuplicateEntries $fromemail $toemail; then
                echo "$fromemail is already in use. Better make an alias the hard way."
                success=1
        else
                writeAndRevirt $fromemail $toemail
                echo "Revirt ran"
                success=0
        fi
}

userMail ()
{
        echo ""
        read -p "Enter email address for this user: " useremail
        read -p "Desired username: " username
        if checkForDuplicateEntries $useremail $username; then
                success=1
        else
                writeAndRevirt $useremail $username
                useradd $username --shell=/bin/false -m
                if [ $? -eq 0 ]; then
                        userpass="`</dev/urandom tr -dc A-Za-z0-9 | head -c16`"
                        echo $userpass|passwd $username --stdin
                else
                        echo "User already exists. Not changing password."
                fi
                echo "Revirt ran"
                success=0
        fi


}

bothMail ()
{
        echo ""
        echo "bothMail function"
        echo "Not ready."
        echo ""
        success=1

}



mailInfo ()
{
        echo ""
        echo "What kind of mail account:"
        echo ""
        select mailoper in "Forward" "Add user account" "Both"
                do
                        break
                done
        case $mailoper in
                "Forward")
                        forwardMail
                ;;
                "Add user account")
                        userMail
                ;;
                "Both")
                        bothMail
                ;;
                *)
                        echo "Bad input. Again do."
                        mailInfo
                ;;

        esac
}

#Main
echo "######################################"
echo "# Mail account creation software v0.2#"
echo "######################################"
echo ""
echo ""
echo ""

#Calling main bulk
mailInfo


#Ending program gracefully
if [ "$success" -eq 1 ];then
        echo "Well, at least you tried."
else
        echo "Ya did it. You can go home now."
fi
#echo -e "\t\t\t --$your_boss"
exit 0

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
# * 2/14/13: Edward
# - finished forwardMail() and userMail()
# * 4/3/13: Edward
# - added list functionality. Takes list of email addresses in a file via commandline
# - Finished bothMail()

writeAndRevirt ()
{
        echo ""
        if [ "$mailoper" == "Both" ];then
                echo -e "$1 \t\t $2_alias" >> /etc/mail/virtusertable
        else
                echo -e "$1 \t\t $2" >> /etc/mail/virtusertable
        fi
        cwd=`pwd`
        cd /etc/mail
        revirt
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

checkForDuplicateAlias ()
{
        echo ""
        areyoustillthere="$(cat /etc/aliases |awk '{print $1;}'|grep $1)"
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
        if [ "$1" != "" ];then
                useremail=$1
                echo -e "Email: $useremail\n"
        else
                read -p "Enter email address for this user: " useremail
        fi
        read -p "Desired username: " username
        if checkForDuplicateEntries $useremail $username; then
                success=1
        else
                writeAndRevirt $useremail $username
                useradd $username --shell=/bin/false -m
                if [ $? -eq 0 ]; then
                        userpass="`</dev/urandom tr -dc A-Za-z0-9 | head -c16`"
                        echo $userpass|passwd $username --stdin
                        echo -e "\n$(tput setaf 2)Client info:$(tput sgr0)"
                        echo "$useremail"
                        echo "$(tput setaf 2)USER:$(tput sgr0) $username"
                        echo -e "$(tput setaf 2)PASS:$(tput sgr0) $userpass\n"
                        ### For cleanup purposes only on edwardo VM ###
                        echo $username >> /root/mcleaner.tmp
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
        userMail
        useralias="${username}_alias"
        echo -e "$useralias: \t\t $useremail,$username" >> /etc/aliases
        newaliases
        echo ""
        success=0

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
echo "# Mail account creation software v1.337#"
echo "######################################"
echo ""
echo ""
echo ""

#Calling main bulk
if [ "$1" != "" ];then
        echo -e "Using a list I see.\nI'm going to assume it's a list of email addresses.\nMaking new users for all of them.\n"
        for i in $(cat $1);do
                echo $i
                userMail $i
        done

else
        mailInfo
fi

#Ending program gracefully
if [ "$success" -eq 1 ];then
        echo "Well, at least you tried."
else
        echo "Ya did it. You can go home now."
fi
exit 0

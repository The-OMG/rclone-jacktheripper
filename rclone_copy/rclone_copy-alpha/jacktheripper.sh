# PERMISSIONS
#	chmod u+x *.sh

# EXECUTE
#	./jacktheripper.sh

cat ./accounts.txt | parallel './rclone-rape.sh {}'

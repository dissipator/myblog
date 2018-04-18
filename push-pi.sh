git add .
echo "git commit . -m $@"
git commit . -m "$@"
ssh pi@192.168.3.2 '~/bin/pull-pi.sh'
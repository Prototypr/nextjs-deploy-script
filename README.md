# NextJS deploy script

This script is for self-hosting a NextJS app with NGINX using PM2 with a 'blue green workflow' that gives:

* Zero downtime – no downtime between deployments
* If the build fails, use the working version
* Auto Deploy - 'git push' to main
* Logs – See the View all the build logs and see build progress in GitHub actions


Here's [the script](https://github.com/Prototypr/nextjs-deploy-script/blob/main/deploy.sh) - ideally triggered from a GitHub action.

Here's [a guide that shows you how to use it and set up blue green deployment]() on your server.

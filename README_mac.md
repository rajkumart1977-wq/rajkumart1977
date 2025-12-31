
Satvik Recipe App — MacBook Quickstart Guide
===========================================

Goal: provide a simple folder you can download to your MacBook that lets you run the full deployment (GitHub + CI + DigitalOcean) or run locally with Docker Compose.

WHAT'S IN THIS ZIP (Mac_Ready_For_MacBook.zip)
- run_all_in_one.sh    -> the script you can run on your Mac (editable)
- README_mac.md        -> this file (simple step-by-step instructions)
- (You must place production_deploy_bundle.zip in the same folder before running)

IMPORTANT: The production_deploy_bundle.zip (full project) must be downloaded separately and placed in the same folder as this script. If you want, I can include it in the zip — tell me to include it and I'll regenerate.

STEP-BY-STEP (for Mac users)
1) Download these files to your Mac (Downloads folder). Move them to a working folder:
   Open Terminal and run:
     mkdir -p ~/satvik && mv ~/Downloads/Run_All_In_One.xlsx ~/satvik/ && cd ~/satvik
   Note: The Excel workbook contained the script earlier — but this zip contains the script as a .sh file ready to run.

2) Install required tools (if you don't have them). Run these one-line installs:
   - Install Homebrew (if not installed):
       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   - Install gh (GitHub CLI), doctl (DigitalOcean CLI), jq, unzip, docker, docker-compose:
       brew install git gh doctl jq unzip
       # Install Docker Desktop from https://www.docker.com/products/docker-desktop and start it (GUI)
   - Login to gh (GitHub CLI):
       gh auth login   (follow prompts - choose GitHub.com, HTTPS, web browser auth)

3) Place production_deploy_bundle.zip in this folder:
   - Download the production_deploy_bundle.zip from the chat (ask "regenerate" if expired) and place the file in the same folder as run_all_in_one.sh
   - Example: move it to ~/satvik/

4) Make the script executable and run it:
   chmod +x run_all_in_one.sh
   # Option A: edit the script to set GITHUB_USER and DO_API_TOKEN OR export env vars:
   export GITHUB_USER="your-github-username"
   export DO_API_TOKEN="your_digitalocean_token"   # optional
   ./run_all_in_one.sh

5) What the script does:
   - Unzips the production bundle into a folder satvik_repo
   - Creates a GitHub repo (if gh is authenticated) and pushes the code
   - Sets GitHub Secrets (DO token + Docker creds) if provided
   - Triggers the GitHub Actions workflow to build & deploy
   - Optionally uses doctl to create the DigitalOcean App
   - Starts a local Docker Compose stack (Postgres + API) for testing

6) After script completes:
   - If deployed to DO, check DigitalOcean App Platform for live URL
   - Create admin user (the script attempts to create admin automatically)
   - Login via POST /auth/login to get JWT, then use the frontend

TROUBLESHOOTING (common issues)
- "gh repo create" fails: ensure gh auth login was completed successfully.
- Docker errors: ensure Docker Desktop is installed and running. On macOS, open Docker Desktop app.
- doctl errors: ensure DO_API_TOKEN is valid and has proper scopes.
- If you run into issues, copy the terminal output and share it with me; I will guide you step-by-step.

SECURITY NOTES
- Do not paste secrets in public chat. Use environment variables or GitHub Secrets (the script sets GH secrets via gh).
- After deployment, change default passwords and secrets to strong values.

If you want, I can rebuild a zip that **includes** production_deploy_bundle.zip inside so you only need to download one file. Reply 'Include bundle' and I'll regenerate the zip to contain both the script and the full project bundle.

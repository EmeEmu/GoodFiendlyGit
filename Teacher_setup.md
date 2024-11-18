This file contains the protocol to prepare the tutorial.

# What you need

For this tutorial you will need to have installed `git`, `git-annex` and `ssh` on your sytem. You can also ask your students to install those tools before the session.

You will also need to have access to a server on which the remote repo will be located. This server should be accessible via ssh by you and your students.


# Setup of remotes

The server will be used as the `git-annex` data repository remote (a.k.a. where the data will be saved remotely). While the repository remote for code will be on GitHub.








# Setup of submodules
git submodule add git@github.com:EmeEmu/GFG_standard_character.git
git commit -am "adding standard character submodule"
git push origin main

# ---+ Extensions
# ---++ MultiSaveContrib

# **PERL EXPERT**
# Registers the save method to the json-rpc server
$Foswiki::cfg{JsonRpcContrib}{Handler}{MultiSaveContrib} = {
  "save" => {
    package => "Foswiki::Contrib::MultiSaveContrib",
    function => "jsonRpcMultiSave",
  }
};

# ---++ JQueryPlugin
# ---+++ Extra plugins

# **STRING EXPERT**
$Foswiki::cfg{JQueryPlugin}{Plugins}{MultiSave}{Module} = 'Foswiki::Contrib::MultiSaveContrib::JQuery';

# **BOOLEAN**
$Foswiki::cfg{JQueryPlugin}{Plugins}{MultiSave}{Enabled} = 1;

1;

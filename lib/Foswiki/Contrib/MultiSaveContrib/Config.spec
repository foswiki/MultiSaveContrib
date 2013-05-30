# ---+ Extensions
# ---++ MultiSaveContrib

# **PERL**
# Registers the save method to the json-rpc server
$Foswiki::cfg{JsonRpcContrib}{Handler}{MultiSaveContrib} = {
  "save" => {
    package => "Foswiki::Contrib::MultiSaveContrib",
    function => "jsonRpcMultiSave",
    options => {},
  }
};

# ---++ JQueryPlugin
# ---+++ Extra plugins

# **STRING**
$Foswiki::cfg{JQueryPlugin}{Plugins}{MultiSave}{Module} = 'Foswiki::Contrib::MultiSaveContrib::JQuery';

# **BOOLEAN**
$Foswiki::cfg{JQueryPlugin}{Plugins}{MultiSave}{Enabled} = 1;

1;

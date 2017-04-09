var run = function() {
  var commonTopic;
  var privateShellTopic;

  var setup_console = function(version){
    var header = 'Interactive Elixir (' + version + ')\n';
    window.jqconsole = $('#console').jqconsole(header, 'parley(1)> ', '...(1)>');

    // register error styles?
    jqconsole.RegisterMatching('**','/0','error');

    // Move to line start Ctrl+A.
    jqconsole.RegisterShortcut('A', function() {
      jqconsole.MoveToStart();
      handler();
    });
    // Move to line end Ctrl+E.
    jqconsole.RegisterShortcut('E', function() {
      jqconsole.MoveToEnd();
      handler();
    });
    // Clear prompt
    jqconsole.RegisterShortcut('R', function() {
      jqconsole.AbortPrompt();
      handler();
    });
  };


  var BLOCK_OPENERS, multiLineHandler,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  BLOCK_OPENERS = ["do"];
  var TOKENS;

  TOKENS = /\s+|\d+(?:\.\d*)?|"(?:[^"]|\\.)*"|'(?:[^']|\\.)*'|\/(?:[^\/]|\\.)*\/|[-+\/*]|[<>=]=?|:?[a-z@$][\w?!]*|[{}()\[\]]|[^\w\s]+/ig;


  var multiLineHandler = function(command) {
    var braces, brackets, last_line_changes, levels, line, parens, token, _i, _j, _len, _len1, _ref, _ref1;
    levels = 0;
    last_line_changes = 0;
    _ref = command.split('\n');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      line = _ref[_i];
      last_line_changes = 0;
      _ref1 = line.match(TOKENS) || [];

      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        token = _ref1[_j];
        if (__indexOf.call(BLOCK_OPENERS, token) >= 0) {
          levels++;
          last_line_changes++;
        } else if (token === 'end') {
          levels--;
          last_line_changes--;
        }
        if (levels < 0) {
          return false;
        }
      }
    }

    if (levels > 0) {
      if (last_line_changes > 0) {
        return 1;
      } else if (last_line_changes < 0) {
        return -1;
      } else {
        return 0;
      }
    } else {
      return false;
    }
  };

  var handleShellServerResponse = function(message) {
    console.log(message);
    var reply = JSON.parse(message.command_result);
    if (reply) {
      prompt = $('.jqconsole-cursor').parent().find('span')[0];
      $(prompt).html(reply.prompt);
      jqconsole.SetPromptLabel(reply.prompt);
      jqconsole.prompt_label_continue = reply.prompt.replace("parley", "...");

      jqconsole.Write(reply.result + '\n', reply.type);
    }
  };

  var evalResultHandler = function(command, identifier) {
    if (command) {
        privateShellTopic.push("shell:" + identifier, {data: command})
          .receive('ok', handleShellServerResponse)
          .receive("error", resp => { console.log("Error evaluating command: ", resp) } )
          .receive('timeout', () => { console.log("Timed out waiting for command") })
    }
    var handler_with_identifier = function(command) {
      evalResultHandler(command, identifier);
    }
    return jqconsole.Prompt(true, handler_with_identifier, multiLineHandler);
  };

  var joinPrivateTopicHandler = function(socket, message, identifier) {
    console.log(message);
    evalResultHandler(null, identifier);
  }

  var preparePrivateTopic = function(socket, identifier) {
    privateShellTopic = socket.channel("shell:" + identifier);
    privateShellTopic.onError( () => console.log("The shell channel reported an error"))
    privateShellTopic.onClose( () => console.log("The shell channel has closed gracefully"))
    privateShellTopic.join()
      .receive("ok", message => joinPrivateTopicHandler(socket, message, identifier))
      .receive("error", resp => { console.log("Error: ", resp) })

    privateShellTopic.on("shell:" + identifier, handleShellServerResponse)
  };

  var joinCommonTopicHandler = function(socket, message) {
    $status.text(message.status);
    setup_console(message.version);

    preparePrivateTopic(socket, message.identifier);
  };

  var _phoenix = require("phoenix");
  var socket = new _phoenix.Socket("/shell", { params: { token: window.userToken } });
  socket.connect();
  var $status = $('#status');

  commonTopic = socket.channel("shell", {});
  commonTopic.onError( () => console.log("The common channel reported an error") )
  commonTopic.onClose( () => console.log("The common channel has closed gracefully") )
  commonTopic.join()
    .receive("ok", message => joinCommonTopicHandler(socket, message))
    .receive("error", resp => { console.log("Error: ", resp) } )

  commonTopic.on("shell", function(message){
    // TODO: Handle broadcasts
  });
};

export var Editor = {
  run: run
}

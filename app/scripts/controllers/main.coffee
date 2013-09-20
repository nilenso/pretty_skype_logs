"use strict"

angular.module("findingBitsV2App").controller "MainCtrl", ($scope) ->

  chatLogRegex = ->
    # example text:
    # [20/09/13 4:53:33 PM] jasim.ab: Do you have any questions so far?
    pattern = ///
            \[(.*?)\]     # capture the date and time.
            \s*           # ignore the spaces
            ([\w\s\.]*)     # capture the username including any dots and whitespace
            :\s           # till the : and the space, which is ignored.
            (.*)          # capture the message - the rest of the line
          ///

  # parse the raw chat text into a hash.
  parseIntoConversation = (input) ->
    lines = input.split('\n')
    conversation = _.map(lines, (line) ->
      [timestamp, username, message] = line.match(chatLogRegex())[1..3]

      parsed_timestamp = moment(timestamp, "DD-MM-YY hh:mm:ss a")
      parsed_timestamp = moment(timestamp, "MM-DD-YY hh:mm:ss a") unless parsed_timestamp.isValid()

      {timestamp: parsed_timestamp, username: username, message: message}
    )
    conversation

  # return unique list of usernames in the conversation
  usersInConversation = (conversation) ->
    # TODO: figure out why _.uniq isn't working directly.
    users = _.map(conversation, (parsed_line) ->
      parsed_line.username
    )
    _.uniq(users)

  # adds `css_class`. this would be of the form 'chatline-user0', 'chatline-user1'.. form.
  transformByAddingUserCssClass = (conversation) ->
    list_of_users = usersInConversation(conversation)
    _.map(conversation, (parsed_line) ->
      user_index = list_of_users.indexOf(parsed_line.username)
      parsed_line.css_class = "chatline-user#{user_index}"
      parsed_line
    )

  # adds `formatted_timestamp`. this can be rendered in HTML. wont repeat if
  # conversation happens between 5 minutes of each other.
  transformByAddingFormattedTimestamp = (conversation) ->

    ALLOWED_TIME_DELTA_MILLISECONDS = (5*60*1000)
    lastConversationAt = null

    _.map(conversation, (parsed_line) ->
      conversationAt = parsed_line.timestamp.toDate()
      timeElapsed = conversationAt - lastConversationAt

      # should I keep this timestamp?
      if (timeElapsed < 0) || (timeElapsed > ALLOWED_TIME_DELTA_MILLISECONDS)
        lastConversationAt = conversationAt
        parsed_line.formatted_timestamp = moment(parsed_line.timestamp).format("h:mmA, ddd Do MMM")
      else # this conversation happened close to the previous. don't show timestamp.
        parsed_line.formatted_timestamp = null

      parsed_line
    )

  # adds `formatted_username`. it won't repeat if the same person
  # has been speaking continuously.
  transformByAddingFormattedUsername = (conversation) ->
    lastSpokenBy = null
    _.map(conversation, (parsed_line) ->
      if lastSpokenBy == parsed_line.username
        parsed_line.formatted_username = null
      else
        parsed_line.formatted_username = parsed_line.username
        lastSpokenBy = parsed_line.username
      parsed_line
    )

  $scope.renderConversation = ->
    $scope.conversation =
      transformByAddingFormattedTimestamp(
        transformByAddingUserCssClass(
          transformByAddingFormattedUsername(
            parseIntoConversation($scope.inputConversationLog)
          )
        )
      )






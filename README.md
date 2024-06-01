# FOSSCU-K Bot

FOSSCU-K Bot is a Telegram bot written in Bash that interacts with GitHub to fetch and display organization members, open issues, and pull requests. Additionally, it provides general-purpose functionalities like fetching user information, downloading profile pictures, and some fun features like calculating IQ for fun.

## Features

- List organization members
- List open issues
- List pull requests
- Display help message with available commands
- Fetch user information
- Download profile pictures
- Fun features like calculating IQ, replace words in msgs, shuffle words etc
- Logging facilities for debugging and monitoring

## Commands

- `/start`: Display the help message
- `/issues`: Fetch and display open issues
- `/prs`: Fetch and display pull requests
- `/members`: Fetch and display organization members

## Installation

1. **Clone the Repository**

    ```bash
    git clone https://github.com/ksauraj/fosscu-bot.git
    cd fosscu-bot
    ```

2. **Set Up Telegram Bot**

    - Create a new bot using [BotFather](https://core.telegram.org/bots#botfather) on Telegram and obtain the bot token.

3. **Set Up GitHub Token**

    - Create a personal access token on GitHub with the necessary permissions to read organization members, repositories, issues, and pull requests.

4. **Run Initialization Script**

    Execute the `init.sh` script to interactively set up the bot:

    ```bash
    chmod +x init.sh bot.sh
    ./init.sh
    ```

    Follow the prompts to input your Telegram bot token, GitHub token, GitHub organization name, and Telegram chat ID.

## Usage

1. **Run the Bot**

    ```bash
    ./bot.sh
    ```

2. **Interact with the Bot**

    - Send `/start` to display the help message.
    - Send `/issues` to fetch and display open issues.
    - Send `/prs` to fetch and display pull requests.
    - Send `/members` to fetch and display organization members.

## Directory Structure

- `init.sh`: Interactive setup script for the bot.
- `utils.sh`: Contains Telegram functions and utilities.
- `bot.sh`: Main script to run the bot.
- `bot.log`: File where log files are stored.

## Additional Features

- **User Information**: Fetch details about a user.
- **Profile Picture Download**: Download and send a user's profile picture.
- **Fun Features**: Fun feature to calculate IQ, Shuffle Words, Replace Words and others for entertainment purposes.

## Contributing

Feel free to submit issues and enhancement requests.

## Inspiration & Credits
`util.sh` was ported from [here](https://github.com/ksauraj/telegram-bash-bot/blob/master/util.sh) which was written by @ksauraj and @Hakimi0804 from scratch. 

**This project is developed & maintained by @ksauraj**

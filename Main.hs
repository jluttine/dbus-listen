module Main (main) where

import Data.Maybe (fromMaybe)
import Control.Monad (forever)
import System.Process (createProcess, shell)
import Control.Concurrent (threadDelay)
import Data.List (intercalate)
import DBus
  ( BusName
  , MemberName
  , InterfaceName
  , ObjectPath
  , Signal
  , parseAddress
  , parseBusName
  , parseInterfaceName
  , parseMemberName
  , parseObjectPath )
import DBus.Client
  ( Client
  , MatchRule
  , connectSession
  , connectSystem
  , connectStarter
  , connect
  , addMatch
  , matchAny
  , matchMember
  , matchInterface
  , matchPath
  , matchPathNamespace
  , matchSender
  , matchDestination
  )
import Options.Applicative
  ( Parser
  , execParser
  , flag
  , flag'
  , long
  , short
  , help
  , metavar
  , optional
  , option
  , maybeReader
  , (<|>)
  , (<**>)
  , some
  , argument
  , str
  , info
  , helper
  , fullDesc
  , progDesc
  , header
  , noIntersperse
  )


-- Client configuration --

sessionBusOption :: Parser (IO Client)
sessionBusOption = flag' connectSession
  (  long "session"
  <> help "Connect to the bus specified in the environment variable DBUS_SESSION_BUS_ADDRESS (this is the default behavior)" )

systemBusOption :: Parser (IO Client)
systemBusOption = flag' connectSystem
  (  long "system"
  <> help "Connect to the bus specified in the environment variable DBUS_SYSTEM_BUS_ADDRESS, or to unix:path=/var/run/dbus/system_bus_socket if DBUS_SYSTEM_BUS_ADDRESS is not set" )

starterBusOption :: Parser (IO Client)
starterBusOption = flag' connectStarter
  (  long "starter"
  <> help "Connect to the bus specified in the environment variable DBUS_STARTER_ADDRESS" )

addressBusOption :: Parser (IO Client)
addressBusOption = connect <$> option (maybeReader parseAddress)
  (  long "address"
  <> metavar "ADDRESS"
  <> help "Connect to the bus at the specified address ADDRESS" )

busOption :: Parser (IO Client)
busOption = fromMaybe connectSession <$> (
  optional $   sessionBusOption
           <|> systemBusOption
           <|> starterBusOption
           <|> addressBusOption )


-- Rule configuration --

createRule :: Maybe BusName -> Maybe BusName -> Maybe ObjectPath -> Maybe ObjectPath -> Maybe InterfaceName -> Maybe MemberName -> MatchRule
createRule sender destination path pathNamespace interface member = matchAny
       { matchSender = sender
       , matchDestination = destination
       , matchPath = path
       , matchPathNamespace = pathNamespace
       , matchInterface = interface
       , matchMember = member
       }

senderOption :: Parser (Maybe BusName)
senderOption = optional $ option (maybeReader parseBusName)
  (  long "sender"
  <> metavar "SEND"
  <> help "If set, only receives signals sent from the given bus name" )

destinationOption :: Parser (Maybe BusName)
destinationOption = optional $ option (maybeReader parseBusName)
  (  long "destination"
  <> metavar "DEST"
  <> help "If set, only receives signals sent to the given bus name" )

pathOption :: Parser (Maybe ObjectPath)
pathOption = optional $ option (maybeReader parseObjectPath)
  (  long "path"
  <> metavar "PATH"
  <> help "If set, only receives signals sent with the given path" )

pathNamespaceOption :: Parser (Maybe ObjectPath)
pathNamespaceOption = optional $ option (maybeReader parseObjectPath)
  (  long "path-namespace"
  <> metavar "NSPATH"
  <> help "If set, only receives signals sent with the given path or any of its children" )

interfaceOption :: Parser (Maybe InterfaceName)
interfaceOption = optional $ option (maybeReader parseInterfaceName)
  (  long "interface"
  <> metavar "IFACE"
  <> help "If set, only receives signals sent with the given interface name" )

memberOption :: Parser (Maybe MemberName)
memberOption = optional $ option (maybeReader parseMemberName)
  (  long "member"
  <> metavar "MEMBER"
  <> help "If set, only receives signals sent with the given member name" )

ruleOption :: Parser MatchRule
ruleOption = createRule <$> senderOption
                        <*> destinationOption
                        <*> pathOption
                        <*> pathNamespaceOption
                        <*> interfaceOption
                        <*> memberOption


-- Verbosity --

data Verbosity = Normal | Verbose

verbosityOption :: Parser Verbosity
verbosityOption = flag Normal Verbose
  (  long "verbose"
  <> short 'v'
  <> help "Enable verbose mode" )


-- Command --

newtype Command = Command [String]

commandArguments :: Parser Command
commandArguments = Command <$> some (argument str (metavar "CMD"))


-- All options and arguments together --

data Options = Options (IO Client) MatchRule Verbosity Command

options :: Parser Options
options = Options <$> busOption
                  <*> ruleOption
                  <*> verbosityOption
                  <*> commandArguments


-- Signal listener --
--
-- TODO/FIXME: 1) How to just wait forever without needing to specify a time for
-- which to wait over and over again? 2) How to exit if the D-Bus thread dies?
listen_ :: Client -> MatchRule -> Verbosity -> Command -> IO ()
listen_ client rule verb (Command args) = addMatch client rule (handleSignal verb)
                                          >> (forever (threadDelay 1000000))
  where
    handleSignal :: Verbosity -> Signal -> IO ()
    handleSignal Normal _ = callback
    handleSignal Verbose sig = (putStrLn . show) sig >> callback

    callback :: IO ()
    callback = createProcess (shell cmd) >> mempty

    cmd :: String
    cmd = intercalate " " args


-- Main --

main :: IO ()
main = run =<< execParser opts
  where
    run (Options ioc r verb cmds) = ioc >>= \c -> listen_ c r verb cmds
    opts = info (options <**> helper)
      (  fullDesc
      <> progDesc "dbus-listen executes CMD on selected D-Bus signals"
      <> header "dbus-listen - execute a command on D-Bus signals"
      -- Don't parse options after the first positional argument so one can use
      -- options in the command that should be executed
      <> noIntersperse )

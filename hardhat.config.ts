import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  defaultNetwork: "ganache",
  networks: {
    polygon: {
      chainId: 137,
      url: "https://polygon-rpc.com",
      accounts: [
        "4da4ac322755d10a4e5571d30e42c919127612816a21e959ec9803bd29ea459a",
      ],
    },
    ganache: {
      chainId: 5777,
      url: "http://127.0.0.1:7545",
      accounts: [
        "4da4ac322755d10a4e5571d30e42c919127612816a21e959ec9803bd29ea459a",
      ],
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;

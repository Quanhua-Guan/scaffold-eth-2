"use client";

import type { NextPage } from "next";
import { useAccount } from "wagmi";
import React, { useState, useEffect } from "react";
import { Address } from "~~/components/scaffold-eth";
import {
  useScaffoldContract,
  useScaffoldReadContract,
  useDeployedContractInfo,
} from "~~/hooks/scaffold-eth";


const Home: NextPage = () => {

  const { address: connectedAddress } = useAccount();

  const { data: OhPandaMEME } = useDeployedContractInfo("OhPandaMEME");

  const [isLoading, setIsLoading] = useState(true);

  const { data: ohPandaMEMEContract } = useScaffoldContract({
    contractName: "OhPandaMEME",
  });

  const { data: balance } = useScaffoldReadContract({
    contractName: "OhPandaMEME",
    functionName: "balanceOf",
    args: [connectedAddress?.toString()],
  });

  const [yourOhPandaMEMEs, setYourOhPandaMEMEs] = useState<any[]>();
  useEffect(() => {
    const updateYourCollectibles = async () => {
      if (balance == undefined || ohPandaMEMEContract == undefined || connectedAddress == undefined) {
        return;
      }

      console.log("Starting...");
      setIsLoading(true);

      const collectibleUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balance; ++tokenIndex) {
        try {
          console.log("Getting token index " + tokenIndex);
          const tokenId = await ohPandaMEMEContract.read.tokenOfOwnerByIndex([connectedAddress, BigInt(tokenIndex)]);
          console.log("tokenId: " + tokenId);
          const tokenURI = await ohPandaMEMEContract.read.tokenURI([tokenId]);
          const jsonManifestString = Buffer.from(tokenURI.substring(29), "base64").toString();
          console.log("jsonManifestString: " + jsonManifestString);

          try {
            const jsonManifest = JSON.parse(jsonManifestString);
            console.log("jsonManifest: " + jsonManifest);
            collectibleUpdate.push({ id: tokenId, uri: tokenURI, owner: connectedAddress, ...jsonManifest });
          } catch (err) {
            console.log(err);
          }
        } catch (err) {
          console.log(err);
        }
      }
      setYourOhPandaMEMEs(collectibleUpdate.reverse());
      setIsLoading(false);
    }
    updateYourCollectibles();
  }, [balance, connectedAddress]);

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center">
            <span className="block text-2xl mb-2">🐼 WELCOME 🐼</span>
            <span className="block text-4xl font-bold">Oh Panda MEME</span>
          </h1>
          <div className="flex justify-center items-center space-x-2">
            <p className="my-2 font-medium">Connected Address:</p>
            <Address address={connectedAddress} />
          </div>

          <div className="flex flex-col text-center">

            {isLoading ? (
              <span>Loading...</span>
            ) : (
              <div>
                {
                  yourOhPandaMEMEs && yourOhPandaMEMEs.length > 0 ?
                    yourOhPandaMEMEs.map(({ id, uri, owner, name, image, description }) => (
                      <div key={id}>
                        <div className="text-center">
                          <span style={{ fontSize: 18, marginRight: 8 }}>{name}</span>
                          <a href={"https://opensea.io/assets/" + OhPandaMEME?.address.toString + "/" + id} target="_blank">
                            <img src={image} />
                          </a>
                          <span>{description}</span>
                          <span>
                            owner:{" "} <Address address={connectedAddress} />
                          </span>
                        </div>
                      </div>
                    ))
                    :
                    <span>...Empty...</span>
                }
              </div>
            )}
          </div>

          <div style={{ width: 820, margin: "auto", paddingBottom: 256 }}>

          </div>

        </div>
      </div >
    </>
  );
};

export default Home;

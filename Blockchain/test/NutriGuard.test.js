const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NutriGuard", function () {
  let nutriGuard;
  let owner;
  let manufacturer;
  let inspector;
  let consumer;

  beforeEach(async function () {
    [owner, manufacturer, inspector, consumer] = await ethers.getSigners();

    const NutriGuard = await ethers.getContractFactory("NutriGuard");
    nutriGuard = await NutriGuard.deploy();
    await nutriGuard.deployed();

    // 授权制造商和检查员
    await nutriGuard.addAuthorizedManufacturer(manufacturer.address);
    await nutriGuard.addAuthorizedInspector(inspector.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await nutriGuard.owner()).to.equal(owner.address);
    });

    it("Should initialize counters to zero", async function () {
      expect(await nutriGuard.ingredientCounter()).to.equal(0);
      expect(await nutriGuard.productCounter()).to.equal(0);
    });
  });

  describe("Authorization", function () {
    it("Should allow owner to add authorized manufacturer", async function () {
      await nutriGuard.addAuthorizedManufacturer(consumer.address);
      expect(await nutriGuard.authorizedManufacturers(consumer.address)).to.be.true;
    });

    it("Should allow owner to add authorized inspector", async function () {
      await nutriGuard.addAuthorizedInspector(consumer.address);
      expect(await nutriGuard.authorizedInspectors(consumer.address)).to.be.true;
    });

    it("Should not allow non-owner to add authorized manufacturer", async function () {
      await expect(
        nutriGuard.connect(manufacturer).addAuthorizedManufacturer(consumer.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Ingredient Registration", function () {
    it("Should allow authorized manufacturer to register ingredient", async function () {
      const tx = await nutriGuard.connect(manufacturer).registerIngredient(
        "Tomato",
        "QmTestHash123"
      );

      await expect(tx)
        .to.emit(nutriGuard, "IngredientRegistered")
        .withArgs(1, manufacturer.address, "Tomato");

      const ingredient = await nutriGuard.getIngredientInfo(1);
      expect(ingredient.name).to.equal("Tomato");
      expect(ingredient.manufacturer).to.equal(manufacturer.address);
      expect(ingredient.isRecalled).to.be.false;
    });

    it("Should not allow unauthorized address to register ingredient", async function () {
      await expect(
        nutriGuard.connect(consumer).registerIngredient("Tomato", "QmTestHash123")
      ).to.be.revertedWith("Not authorized manufacturer");
    });
  });

  describe("Quality Data Recording", function () {
    beforeEach(async function () {
      // 注册一个原料
      await nutriGuard.connect(manufacturer).registerIngredient("Tomato", "QmTestHash123");
    });

    it("Should allow authorized inspector to record quality data", async function () {
      const tx = await nutriGuard.connect(inspector).recordQualityData(
        1, // ingredientId
        20, // temperature (20°C)
        50, // humidity (50%)
        100, // weight (100g)
        '{"sensor": "DHT22", "location": "warehouse1"}'
      );

      await expect(tx)
        .to.emit(nutriGuard, "QualityDataRecorded")
        .withArgs(1, await ethers.provider.getBlockNumber().then(n => ethers.provider.getBlock(n).then(b => b.timestamp)), true);

      const record = await nutriGuard.getQualityRecord(1, 0);
      expect(record.temperature).to.equal(20);
      expect(record.humidity).to.equal(50);
      expect(record.weight).to.equal(100);
      expect(record.qualityPassed).to.be.true;
    });

    it("Should mark quality as failed for out-of-range values", async function () {
      await nutriGuard.connect(inspector).recordQualityData(
        1,
        100, // temperature too high
        50,
        100,
        '{"sensor": "DHT22"}'
      );

      const record = await nutriGuard.getQualityRecord(1, 0);
      expect(record.qualityPassed).to.be.false;
    });
  });

  describe("Product Creation", function () {
    beforeEach(async function () {
      // 注册两个原料
      await nutriGuard.connect(manufacturer).registerIngredient("Tomato", "QmTestHash1");
      await nutriGuard.connect(manufacturer).registerIngredient("Lettuce", "QmTestHash2");
    });

    it("Should allow manufacturer to create product with valid ingredients", async function () {
      const tx = await nutriGuard.connect(manufacturer).createProduct(
        [1, 2], // ingredientIds
        "QmQRCodeHash",
        "QmProductHash"
      );

      await expect(tx)
        .to.emit(nutriGuard, "ProductCreated")
        .withArgs(1, manufacturer.address, [1, 2]);

      const product = await nutriGuard.getProductInfo(1);
      expect(product.manufacturer).to.equal(manufacturer.address);
      expect(product.ingredientIds.length).to.equal(2);
      expect(product.isValid).to.be.true;
    });

    it("Should not allow creating product with recalled ingredient", async function () {
      // 召回第一个原料
      await nutriGuard.connect(inspector).initiateRecall(1, "Contamination detected");

      await expect(
        nutriGuard.connect(manufacturer).createProduct([1, 2], "QmQRCode", "QmProduct")
      ).to.be.revertedWith("Cannot use recalled ingredient");
    });
  });

  describe("Recall System", function () {
    beforeEach(async function () {
      // 注册原料并创建产品
      await nutriGuard.connect(manufacturer).registerIngredient("Tomato", "QmTestHash1");
      await nutriGuard.connect(manufacturer).createProduct([1], "QmQRCode", "QmProduct");
    });

    it("Should allow inspector to initiate recall", async function () {
      const tx = await nutriGuard.connect(inspector).initiateRecall(1, "Contamination detected");

      await expect(tx)
        .to.emit(nutriGuard, "RecallInitiated")
        .withArgs(1, "Contamination detected", await ethers.provider.getBlockNumber().then(n => ethers.provider.getBlock(n).then(b => b.timestamp)));

      const ingredient = await nutriGuard.getIngredientInfo(1);
      expect(ingredient.isRecalled).to.be.true;
    });

    it("Should return affected products for recalled ingredient", async function () {
      const affectedProducts = await nutriGuard.getAffectedProducts(1);
      expect(affectedProducts.length).to.equal(1);
      expect(affectedProducts[0]).to.equal(1);
    });

    it("Should invalidate products when ingredient is recalled", async function () {
      // 召回原料
      await nutriGuard.connect(inspector).initiateRecall(1, "Contamination");

      // 验证产品
      const isValid = await nutriGuard.verifyProduct(1);
      expect(isValid).to.be.false;

      const product = await nutriGuard.getProductInfo(1);
      expect(product.isValid).to.be.false;
    });
  });
});




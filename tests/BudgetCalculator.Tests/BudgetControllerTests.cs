using BudgetCalculator.Api.Controllers;
using BudgetCalculator.Api.Models;
using Microsoft.AspNetCore.Mvc;

namespace BudgetCalculator.Tests;

public class BudgetControllerTests
{
    private readonly BudgetController _controller = new();

    private static decimal ReadTotalAmount(OkObjectResult ok)
    {
        var value = ok.Value ?? throw new InvalidOperationException("Ok result has no value.");
        var prop = value.GetType().GetProperty("TotalAmount")
            ?? throw new InvalidOperationException("TotalAmount property was not found.");
        return Assert.IsType<decimal>(prop.GetValue(value));
    }

    [Fact]
    public void Calculate_HappyPath_WithoutInsurance_Returns200And500()
    {
        var request = new BudgetRequest
        {
            DailyCost = 100m,
            Days = 5,
            IncludeInsurance = false
        };

        var result = _controller.Calculate(request);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(200, ok.StatusCode ?? 200);
        Assert.Equal(500m, ReadTotalAmount(ok));
    }

    [Fact]
    public void Calculate_WithInsurance_Returns200And525()
    {
        var request = new BudgetRequest
        {
            DailyCost = 100m,
            Days = 5,
            IncludeInsurance = true
        };

        var result = _controller.Calculate(request);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(200, ok.StatusCode ?? 200);
        Assert.Equal(525m, ReadTotalAmount(ok));
    }

    [Fact]
    public void Calculate_NegativeDays_ReturnsBadRequest()
    {
        var request = new BudgetRequest
        {
            DailyCost = 100m,
            Days = -1,
            IncludeInsurance = false
        };

        var result = _controller.Calculate(request);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal(400, bad.StatusCode ?? 400);
        Assert.Equal("Days must be greater than zero.", bad.Value);
    }

    [Fact]
    public void Calculate_ZeroDays_ReturnsBadRequest()
    {
        var request = new BudgetRequest
        {
            DailyCost = 100m,
            Days = 0,
            IncludeInsurance = false
        };

        var result = _controller.Calculate(request);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal(400, bad.StatusCode ?? 400);
        Assert.Equal("Days must be greater than zero.", bad.Value);
    }

    [Fact]
    public void Calculate_ZeroDailyCost_Returns200And0()
    {
        var request = new BudgetRequest
        {
            DailyCost = 0m,
            Days = 5,
            IncludeInsurance = false
        };

        var result = _controller.Calculate(request);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(200, ok.StatusCode ?? 200);
        Assert.Equal(0m, ReadTotalAmount(ok));
    }

    [Fact]
    public void Calculate_DecimalDailyCost_ReturnsExactTotal()
    {
        var request = new BudgetRequest
        {
            DailyCost = 100.50m,
            Days = 3,
            IncludeInsurance = false
        };

        var result = _controller.Calculate(request);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(200, ok.StatusCode ?? 200);
        Assert.Equal(301.50m, ReadTotalAmount(ok));
    }
}

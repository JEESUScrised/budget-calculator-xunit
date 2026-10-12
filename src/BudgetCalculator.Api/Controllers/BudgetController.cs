using BudgetCalculator.Api.Models;
using Microsoft.AspNetCore.Mvc;

namespace BudgetCalculator.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BudgetController : ControllerBase
{
    [HttpPost("calculate")]
    public IActionResult Calculate([FromBody] BudgetRequest request)
    {
        if (request.Days <= 0)
        {
            return BadRequest("Days must be greater than zero.");
        }

        decimal total = request.DailyCost * request.Days;

        if (request.IncludeInsurance)
        {
            total *= 1.05m;
        }

        return Ok(new { TotalAmount = total });
    }
}

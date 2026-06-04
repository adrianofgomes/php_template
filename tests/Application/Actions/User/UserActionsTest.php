<?php

declare(strict_types=1);

namespace App\Tests\Application\Actions\User;

use App\Tests\TestCase;

class UserActionsTest extends TestCase
{
    public function testIsAdminActionUnauthenticated()
    {
        $app = $this->getAppInstance();
        $request = $this->createRequest('GET', '/users/me/is-admin');
        
        try {
            $response = $app->handle($request);
            $this->assertEquals(401, $response->getStatusCode());
        } catch (\Slim\Exception\HttpUnauthorizedException $e) {
            $this->assertEquals('Authorization header missing.', $e->getMessage());
        }
    }

    public function testIsAdminActionWithMockToken()
    {
        $app = $this->getAppInstance();
        
        $request = $this->createRequest('GET', '/users/123456789/is-admin');
        $request = $request->withHeader('Authorization', 'Bearer test-token');
        
        try {
            $response = $app->handle($request);
            $this->assertContains($response->getStatusCode(), [200, 403]);
        } catch (\Slim\Exception\HttpForbiddenException $e) {
            $this->assertStringContainsString('Cadastro em validação', $e->getMessage());
        }
    }

    public function testAdminRouteAccessDeniedForNormalUser()
    {
        $app = $this->getAppInstance();
        
        $request = $this->createRequest('GET', '/users/admin/pending');
        $request = $request->withHeader('Authorization', 'Bearer new-user-token');
        
        try {
            $response = $app->handle($request);
            $this->assertEquals(403, $response->getStatusCode());
        } catch (\Slim\Exception\HttpForbiddenException $e) {
            $this->assertStringContainsString('Cadastro em validação', $e->getMessage());
        }
    }
}

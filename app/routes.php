<?php

declare(strict_types=1);

use App\Application\Actions\User\IsAdminAction;
use App\Application\Actions\User\ListPendingUsersAction;
use App\Application\Actions\User\ApproveUserAction;
use App\Application\Middleware\AuthMiddleware;
use App\Application\Middleware\AdminMiddleware;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\App;
use Slim\Interfaces\RouteCollectorProxyInterface as Group;

return function (App $app) {
    $app->options('/{routes:.*}', function (Request $request, Response $response) {
        // CORS Pre-Flight OPTIONS Request Handler
        return $response;
    });

    $app->get('/', function (Request $request, Response $response) {
        $response->getBody()->write('Hello world!');
        return $response;
    });

    // Authenticated Routes
    $app->group('/users', function (Group $group) {
        $group->get('/{google_id}/is-admin', IsAdminAction::class);
        
        // Admin Only Routes
        $group->group('/admin', function (Group $adminGroup) {
            $adminGroup->get('/pending', ListPendingUsersAction::class);
            $adminGroup->post('/{google_id}/approve', ApproveUserAction::class);
        })->add(AdminMiddleware::class);
        
    })->add(AuthMiddleware::class);
};
